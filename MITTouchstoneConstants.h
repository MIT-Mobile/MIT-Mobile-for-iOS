#import <Foundation/Foundation.h>

extern NSString* const MITECPErrorDomain;

NS_ENUM(NSInteger, MITECPErrorCode) {
    MITECPErrorInvalidXML = 0xA00,
    MITECPErrorUnknown,
    MITECPErrorFault
};

enum : int {
    MIT_XML_COPY_SHALLOW = 0,
    MIT_XML_COPY_RECURSIVE = 1, //recursive copy (properties, namespaces and children when applicable)
    MIT_XML_COPY_DEEP = 2 //copy properties and namespaces only (when applicable)
};

extern NSString* const MITSOAPNamespaceURI;

extern NSString* const MITSOAPFaultXPath;
extern NSString* const MITSOAPFaultCodeXPath;
extern NSString* const MITSOAPFaultStringXPath;
extern NSString* const MITSOAPHeaderXPath;


extern NSString* const MITECPNamespaceURI;
extern NSString* const MITPAOSNamespaceURI;

extern NSString* const MITECPAssertionConsumerXPath;
extern NSString* const MITECPRelayStateXPath;
extern NSString* const MITECPResponseConsumerXPath;

extern NSString* const MITECPMIMEType;
extern NSString* const MITECPPAOSHeaderName;
