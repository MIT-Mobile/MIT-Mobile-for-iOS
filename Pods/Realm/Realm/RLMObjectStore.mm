////////////////////////////////////////////////////////////////////////////
//
// Copyright 2014 Realm Inc.
//
// Licensed under the Apache License, Version 2.0 (the "License");
// you may not use this file except in compliance with the License.
// You may obtain a copy of the License at
//
// http://www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing, software
// distributed under the License is distributed on an "AS IS" BASIS,
// WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
// See the License for the specific language governing permissions and
// limitations under the License.
//
////////////////////////////////////////////////////////////////////////////

#import "RLMObjectStore.hpp"

#import "RLMArray_Private.hpp"
#import "RLMListBase.h"
#import "RLMObjectSchema_Private.hpp"
#import "RLMObject_Private.h"
#import "RLMProperty_Private.h"
#import "RLMQueryUtil.hpp"
#import "RLMRealm_Private.hpp"
#import "RLMUtil.hpp"

#import <objc/message.h>

extern "C" {

static void RLMVerifyAndAlignColumns(RLMObjectSchema *tableSchema, RLMObjectSchema *objectSchema) {
    NSMutableArray *properties = [NSMutableArray arrayWithCapacity:objectSchema.properties.count];
    NSMutableArray *exceptionMessages = [NSMutableArray array];

    // check to see if properties are the same
    for (RLMProperty *tableProp in tableSchema.properties) {
        RLMProperty *schemaProp = objectSchema[tableProp.name];
        if (!schemaProp) {
            [exceptionMessages addObject:[NSString stringWithFormat:@"Property '%@' is missing from latest object model.", tableProp.name]];
            continue;
        }
        if (tableProp.type != schemaProp.type) {
            [exceptionMessages addObject:[NSString stringWithFormat:@"Property types for '%@' property do not match. Old type '%@', new type '%@'.",
                                          tableProp.name, RLMTypeToString(tableProp.type), RLMTypeToString(schemaProp.type)]];
            continue;
        }
        if (tableProp.type == RLMPropertyTypeObject || tableProp.type == RLMPropertyTypeArray) {
            if (![tableProp.objectClassName isEqualToString:schemaProp.objectClassName]) {
                [exceptionMessages addObject:[NSString stringWithFormat:@"Target object type for property '%@' does not match. Old type '%@', new type '%@'.",
                                              tableProp.name, tableProp.objectClassName, schemaProp.objectClassName]];
            }
        }
        if (tableProp.isPrimary != schemaProp.isPrimary) {
            if (tableProp.isPrimary) {
                [exceptionMessages addObject:[NSString stringWithFormat:@"Property '%@' is no longer a primary key.", tableProp.name]];
            }
            else {
                [exceptionMessages addObject:[NSString stringWithFormat:@"Property '%@' has been made a primary key.", tableProp.name]];
            }
        }

        // create new property with aligned column
        schemaProp.column = tableProp.column;
        [properties addObject:schemaProp];
    }

    // check for new missing properties
    for (RLMProperty *schemaProp in objectSchema.properties) {
        if (!tableSchema[schemaProp.name]) {
            [exceptionMessages addObject:[NSString stringWithFormat:@"Property '%@' has been added to latest object model.", schemaProp.name]];
        }
    }

    // throw if errors
    if (exceptionMessages.count) {
        @throw [NSException exceptionWithName:@"RLMException"
                                       reason:[NSString stringWithFormat:@"Migration is required for object type '%@' due to the following errors:\n- %@",
                                               objectSchema.className, [exceptionMessages componentsJoinedByString:@"\n- "]]
                                     userInfo:nil];
    }

    // set new properties array with correct column alignment
    objectSchema.properties = properties;
}

// create a column for a property in a table
// NOTE: must be called from within write transaction
static void RLMCreateColumn(RLMRealm *realm, tightdb::Table &table, RLMProperty *prop) {
    switch (prop.type) {
            // for objects and arrays, we have to specify target table
        case RLMPropertyTypeObject:
        case RLMPropertyTypeArray: {
            tightdb::TableRef linkTable = RLMTableForObjectClass(realm, prop.objectClassName);
            prop.column = table.add_column_link(tightdb::DataType(prop.type), prop.name.UTF8String, *linkTable);
            break;
        }
        default: {
            prop.column = table.add_column(tightdb::DataType(prop.type), prop.name.UTF8String);
            if (prop.attributes & RLMPropertyAttributeIndexed) {
                // FIXME - support other types
                if (prop.type != RLMPropertyTypeString) {
                    NSLog(@"RLMPropertyAttributeIndexed only supported for 'NSString' properties");
                }
                else {
                    table.add_search_index(prop.column);
                }
            }
        }
    }
}

// Schema used to created generated accessors
static NSMutableArray * const s_accessorSchema = [NSMutableArray new];

void RLMRealmCreateAccessors(RLMSchema *schema) {
    // create accessors for non-dynamic realms
    RLMSchema *matchingSchema = nil;
    for (RLMSchema *accessorSchema in s_accessorSchema) {
        if ([schema isEqualToSchema:accessorSchema]) {
            matchingSchema = accessorSchema;
            break;
        }
    }

    if (matchingSchema) {
        // reuse accessors
        for (RLMObjectSchema *objectSchema in schema.objectSchema) {
            objectSchema.accessorClass = matchingSchema[objectSchema.className].accessorClass;
        }
    }
    else {
        // create accessors and cache in s_accessorSchema
        for (RLMObjectSchema *objectSchema in schema.objectSchema) {
            if (objectSchema.table) {
                NSString *prefix = [NSString stringWithFormat:@"RLMAccessor_v%lu_",
                                    (unsigned long)s_accessorSchema.count];
                objectSchema.accessorClass = RLMAccessorClassForObjectClass(objectSchema.objectClass, objectSchema, prefix);
            }
        }
        [s_accessorSchema addObject:schema];
    }
}

void RLMClearAccessorCache() {
    [s_accessorSchema removeAllObjects];
}

void RLMRealmSetSchema(RLMRealm *realm, RLMSchema *targetSchema, bool verify) {
    realm.schema = targetSchema;

    for (RLMObjectSchema *objectSchema in realm.schema.objectSchema) {
        objectSchema.realm = realm;

        // read-only realms may be missing tables entirely
        if (verify && objectSchema.table) {
            RLMObjectSchema *tableSchema = [RLMObjectSchema schemaFromTableForClassName:objectSchema.className realm:realm];
            RLMVerifyAndAlignColumns(tableSchema, objectSchema);
        }
    }
}

static bool RLMPropertyHasChanged(RLMProperty *p1, RLMProperty *p2) {
    return p2 == nil
        || p1.type != p2.type
        || ![p1.name isEqualToString:p2.name]
        || (p1.objectClassName != p2.objectClassName && ![p1.objectClassName isEqualToString:p2.objectClassName]);
}

// sets a realm's schema to a copy of targetSchema and creates/updates tables
// if update existing is true, updates existing tables, otherwise validates existing tables
// NOTE: must be called from within write transaction
static bool RLMRealmCreateTables(RLMRealm *realm, RLMSchema *targetSchema, bool updateExisting) {
    // create metadata tables if neded
    bool changed = RLMRealmCreateMetadataTables(realm);

    // first pass to create missing tables
    NSMutableArray *objectSchemaToUpdate = [NSMutableArray array];
    for (RLMObjectSchema *objectSchema in targetSchema.objectSchema) {
        bool created = false;
        objectSchema.table = RLMTableForObjectClass(realm, objectSchema.className, created).get();

        // we will modify tables for any new objectSchema (table was created) or for all if updateExisting is true
        if (updateExisting || created) {
            [objectSchemaToUpdate addObject:objectSchema];
            changed = true;
        }
    }

    // second pass adds/removes columns for objectSchemaToUpdate
    for (RLMObjectSchema *objectSchema in objectSchemaToUpdate) {
        RLMObjectSchema *tableSchema = [RLMObjectSchema schemaFromTableForClassName:objectSchema.className realm:realm];

        // add missing columns
        for (RLMProperty *prop in objectSchema.properties) {
            // add any new properties (new name or different type)
            if (RLMPropertyHasChanged(prop, tableSchema[prop.name])) {
                RLMCreateColumn(realm, *objectSchema.table, prop);
                changed = true;
            }
        }

        // remove extra columns
        for (int i = (int)tableSchema.properties.count - 1; i >= 0; i--) {
            RLMProperty *prop = tableSchema.properties[i];
            if (RLMPropertyHasChanged(prop, objectSchema[prop.name])) {
                objectSchema.table->remove_column(prop.column);
                changed = true;
            }
        }

        // update table metadata
        if (objectSchema.primaryKeyProperty != nil) {
            // if there is a primary key set, check if it is the same as the old key
            if (tableSchema.primaryKeyProperty == nil || ![tableSchema.primaryKeyProperty isEqual:objectSchema.primaryKeyProperty]) {
                RLMRealmSetPrimaryKeyForObjectClass(realm, objectSchema.className, objectSchema.primaryKeyProperty.name);
                changed = true;
            }
        }
        else if (tableSchema.primaryKeyProperty) {
            // there is no primary key, so if thre was one nil out
            RLMRealmSetPrimaryKeyForObjectClass(realm, objectSchema.className, nil);
            changed = true;
        }
    }

    // FIXME - remove deleted tables

    // set and validate final schema
    RLMRealmSetSchema(realm, targetSchema, true);

    return changed;
}

NSError *RLMUpdateRealmToSchemaVersion(RLMRealm *realm, NSUInteger newVersion, RLMSchema *targetSchema, NSError *(^migrationBlock)()) {
    [realm beginWriteTransaction];

    @try {
        NSUInteger oldVersion = RLMRealmSchemaVersion(realm);

        // validate versions
        if (oldVersion > newVersion && oldVersion != RLMNotVersioned) {
            @throw [NSException exceptionWithName:@"RLMException"
                                           reason:@"Version of Realm file on disk is higher than current schema version"
                                         userInfo:@{@"path" : realm.path}];
        }

        // create tables
        bool migrating = oldVersion != newVersion;
        bool changed = RLMRealmCreateTables(realm, targetSchema, migrating);

        if (migrating) {
            // apply migration block if provided
            if (migrationBlock) {
                NSError *error = migrationBlock();
                if (error) {
                    [realm cancelWriteTransaction];
                    return error;
                }
            }

            RLMRealmSetSchemaVersion(realm, newVersion);
            changed = true;
        }

        if (changed) {
            [realm commitWriteTransaction];
        }
        else {
            [realm cancelWriteTransaction];
        }
    }
    @catch (NSException *) {
        [realm cancelWriteTransaction];
        @throw;
    }

    return nil;
}

static inline void RLMVerifyInWriteTransaction(RLMRealm *realm) {
    // if realm is not writable throw
    if (!realm.inWriteTransaction) {
        @throw [NSException exceptionWithName:@"RLMException"
                                       reason:@"Can only add, remove, or create objects in a Realm in a write transaction - call beginWriteTransaction on an RLMRealm instance first."
                                     userInfo:nil];
    }
    RLMCheckThread(realm);
}

static inline void RLMInitializeSwiftListAccessor(RLMObjectBase *object) {
    // switch List<> properties to linkviews from standalone arrays
    for (RLMProperty *prop in object.objectSchema.properties) {
        if (prop.swiftListIvar) {
            auto list = static_cast<RLMListBase *>(object_getIvar(object, prop.swiftListIvar));
            list._rlmArray = [RLMArrayLinkView arrayWithObjectClassName:prop.objectClassName
                                                                   view:object->_row.get_linklist(prop.column)
                                                                  realm:object->_realm];
        }
    }
}

} // extern "C" {

template<typename F>
static inline NSUInteger RLMCreateOrGetRowForObject(RLMObjectSchema *schema, F primaryValueGetter, RLMCreationOptions options, bool &created) {
    // try to get existing row if updating
    size_t rowIndex = tightdb::not_found;
    tightdb::Table &table = *schema.table;
    RLMProperty *primaryProperty = schema.primaryKeyProperty;
    if ((options & RLMCreationOptionsUpdateOrCreate) && primaryProperty) {
        // get primary value
        id primaryValue = primaryValueGetter(primaryProperty);
        
        // search for existing object based on primary key type
        if (primaryProperty.type == RLMPropertyTypeString) {
            rowIndex = table.find_first_string(primaryProperty.column, RLMStringDataWithNSString(primaryValue));
        }
        else {
            rowIndex = table.find_first_int(primaryProperty.column, [primaryValue longLongValue]);
        }
    }

    // if no existing, create row
    created = NO;
    if (rowIndex == tightdb::not_found) {
        rowIndex = table.add_empty_row();
        created = YES;
    }

    // get accessor
    return rowIndex;
}

extern "C" {

void RLMAddObjectToRealm(RLMObjectBase *object, RLMRealm *realm, RLMCreationOptions options) {
    RLMVerifyInWriteTransaction(realm);

    // verify that object is standalone
    if (object.invalidated) {
        @throw [NSException exceptionWithName:@"RLMException"
                                       reason:@"Adding a deleted or invalidated object to a Realm is not permitted"
                                     userInfo:nil];
    }
    if (object.realm) {
        if (object.realm == realm) {
            // no-op
            return;
        }
        // for differing realms users must explicitly create the object in the second realm
        @throw [NSException exceptionWithName:@"RLMException"
                                       reason:@"Object is already persisted in a Realm"
                                     userInfo:nil];
    }

    // set the realm and schema
    NSString *objectClassName = object.objectSchema.className;
    RLMObjectSchema *schema = realm.schema[objectClassName];
    object.objectSchema = schema;
    object.realm = realm;

    // get or create row
    bool created;
    auto primaryGetter = [=](RLMProperty *p) { return [object valueForKey:p.getterName]; };
    object->_row = (*schema.table)[RLMCreateOrGetRowForObject(schema, primaryGetter, options, created)];

    // populate all properties
    for (RLMProperty *prop in schema.properties) {
        // get object from ivar using key value coding
        id value = nil;
        if (prop.swiftListIvar) {
            value = static_cast<RLMListBase *>(object_getIvar(object, prop.swiftListIvar))._rlmArray;
        }
        else if ([object respondsToSelector:prop.getterSel]) {
            value = [object valueForKey:prop.getterName];
        }

        // FIXME: Add condition to check for Mixed once it can support a nil value.
        if (!value && prop.type != RLMPropertyTypeObject) {
            @throw [NSException exceptionWithName:@"RLMException"
                                           reason:[NSString stringWithFormat:@"No value or default value specified for property '%@' in '%@'",
                                                   prop.name, schema.className]
                                         userInfo:nil];
        }

        // set in table with out validation
        // skip primary key when updating since it doesn't change
        if (created || !prop.isPrimary) {
            RLMDynamicSet(object, prop, value, options | (prop.isPrimary ? RLMCreationOptionsEnforceUnique : 0));
        }

        // set the ivars for object and array properties to nil as otherwise the
        // accessors retain objects that are no longer accessible via the properties
        // this is mainly an issue when the object graph being added has cycles,
        // as it's not obvious that the user has to set the *ivars* to nil to
        // avoid leaking memory
        if (prop.type == RLMPropertyTypeObject || prop.type == RLMPropertyTypeArray) {
            if (!prop.swiftListIvar) {
                ((void(*)(id, SEL, id))objc_msgSend)(object, prop.setterSel, nil);
            }
        }
    }

    // set to proper accessor class
    object_setClass(object, schema.accessorClass);

    RLMInitializeSwiftListAccessor(object);
}


RLMObjectBase *RLMCreateObjectInRealmWithValue(RLMRealm *realm, NSString *className, id value, RLMCreationOptions options) {
    if (RLMIsSubclass([value class], RLMObjectBase.class) &&
        [[[(RLMObjectBase *)value class] className] isEqualToString:className] &&
        [(RLMObjectBase *)value realm] == realm) {
        // This is a no-op if value is an RLMObject of the same type already backed by the target realm.
        return value;
    }

    // verify writable
    RLMVerifyInWriteTransaction(realm);

    // create the object
    RLMSchema *schema = realm.schema;
    RLMObjectSchema *objectSchema = schema[className];
    RLMObjectBase *object = [[objectSchema.accessorClass alloc] initWithRealm:realm schema:objectSchema defaultValues:NO];

    // validate values, create row, and populate
    if (NSArray *array = RLMDynamicCast<NSArray>(value)) {
        array = RLMValidatedArrayForObjectSchema(value, objectSchema, schema);

        // get or create our accessor
        bool created;
        auto primaryGetter = [=](RLMProperty *p) { return array[p.column]; };
        object->_row = (*objectSchema.table)[RLMCreateOrGetRowForObject(objectSchema, primaryGetter, options, created)];

        // populate
        NSArray *props = objectSchema.properties;
        for (NSUInteger i = 0; i < array.count; i++) {
            RLMProperty *prop = props[i];
            // skip primary key when updating since it doesn't change
            if (created || !prop.isPrimary) {
                RLMDynamicSet(object, prop, array[i],
                              options | RLMCreationOptionsUpdateOrCreate | (prop.isPrimary ? RLMCreationOptionsEnforceUnique : 0));
            }
        }
    }
    else {
        // get or create our accessor
        bool created;
        auto primaryGetter = [=](RLMProperty *p) { return [value valueForKey:p.name]; };
        object->_row = (*objectSchema.table)[RLMCreateOrGetRowForObject(objectSchema, primaryGetter, options, created)];

        // assume dictionary or object with kvc properties
        NSDictionary *dict = RLMValidatedDictionaryForObjectSchema(value, objectSchema, schema, !created);

        // populate
        for (RLMProperty *prop in objectSchema.properties) {
            // skip missing properties and primary key when updating since it doesn't change
            id propValue = dict[prop.name];
            if (propValue && (created || !prop.isPrimary)) {
                RLMDynamicSet(object, prop, propValue,
                              options | RLMCreationOptionsUpdateOrCreate | (prop.isPrimary ? RLMCreationOptionsEnforceUnique : 0));
            }
        }
    }

    RLMInitializeSwiftListAccessor(object);
    return object;
}

void RLMDeleteObjectFromRealm(RLMObjectBase *object) {
    RLMVerifyInWriteTransaction(object.realm);

    // move last row to row we are deleting
    if (object->_row.is_attached()) {
        object->_row.get_table()->move_last_over(object->_row.get_index());
    }

    // set realm to nil
    object.realm = nil;
}

void RLMDeleteAllObjectsFromRealm(RLMRealm *realm) {
    RLMVerifyInWriteTransaction(realm);

    // clear table for each object schema
    for (RLMObjectSchema *objectSchema in realm.schema.objectSchema) {
        objectSchema.table->clear();
    }
}

RLMResults *RLMGetObjects(RLMRealm *realm, NSString *objectClassName, NSPredicate *predicate) {
    RLMCheckThread(realm);

    // create view from table and predicate
    RLMObjectSchema *objectSchema = realm.schema[objectClassName];
    if (!objectSchema.table) {
        // read-only realms may be missing tables since we can't add any
        // missing ones on init
        return [RLMEmptyResults emptyResultsWithObjectClassName:objectClassName realm:realm];
    }

    if (predicate) {
        tightdb::Query query = objectSchema.table->where();
        RLMUpdateQueryWithPredicate(&query, predicate, realm.schema, objectSchema);

        // create and populate array
        return [RLMResults resultsWithObjectClassName:objectClassName
                                                query:std::make_unique<Query>(query)
                                                realm:realm];
    }

    return [RLMTableResults tableResultsWithObjectSchema:objectSchema realm:realm];
}

id RLMGetObject(RLMRealm *realm, NSString *objectClassName, id key) {
    RLMCheckThread(realm);

    RLMObjectSchema *objectSchema = realm.schema[objectClassName];

    RLMProperty *primaryProperty = objectSchema.primaryKeyProperty;
    if (!primaryProperty) {
        NSString *msg = [NSString stringWithFormat:@"%@ does not have a primary key", objectClassName];
        @throw [NSException exceptionWithName:@"RLMException" reason:msg userInfo:nil];
    }

    if (!objectSchema.table) {
        // read-only realms may be missing tables since we can't add any
        // missing ones on init
        return nil;
    }

    size_t row = tightdb::not_found;
    if (primaryProperty.type == RLMPropertyTypeString) {
        if (NSString *str = RLMDynamicCast<NSString>(key)) {
            row = objectSchema.table->find_first_string(primaryProperty.column, RLMStringDataWithNSString(str));
        }
        else {
            @throw [NSException exceptionWithName:@"RLMException"
                                           reason:[NSString stringWithFormat:@"Invalid value '%@' for primary key", key]
                                         userInfo:nil];
        }
    }
    else {
        if (NSNumber *number = RLMDynamicCast<NSNumber>(key)) {
            row = objectSchema.table->find_first_int(primaryProperty.column, number.longLongValue);
        }
        else {
            @throw [NSException exceptionWithName:@"RLMException"
                                           reason:[NSString stringWithFormat:@"Invalid value '%@' for primary key", key]
                                         userInfo:nil];
        }
    }

    if (row == tightdb::not_found) {
        return nil;
    }

    return RLMCreateObjectAccessor(realm, objectSchema, row);
}

// Create accessor and register with realm
RLMObjectBase *RLMCreateObjectAccessor(__unsafe_unretained RLMRealm *realm,
                                   	   __unsafe_unretained RLMObjectSchema *objectSchema,
                                  	   NSUInteger index) {
    RLMObjectBase *accessor = [[objectSchema.accessorClass alloc] initWithRealm:realm schema:objectSchema defaultValues:NO];
    accessor->_row = (*objectSchema.table)[index];
    RLMInitializeSwiftListAccessor(accessor);
    return accessor;
}

} // extern "C" {
