#import "MITTouchstoneConstants.h"

NSString* const MITSOAPNamespaceURI = @"http://schemas.xmlsoap.org/soap/envelope/";
NSString* const MITECPNamespaceURI = @"urn:oasis:names:tc:SAML:2.0:profiles:SSO:ecp";
NSString* const MITPAOSNamespaceURI = @"urn:liberty:paos:2003-08";

NSString* const MITSOAPFaultXPath = @"/soap:Envelope/soap:Body/soap:Fault";
NSString* const MITSOAPFaultCodeXPath = @"/soap:Envelope/soap:Body/soap:Fault/soap:faultcode";
NSString* const MITSOAPFaultStringXPath = @"/soap:Envelope/soap:Body/soap:Fault/soap:faultstring";
NSString* const MITSOAPHeaderXPath = @"/soap:Envelope/soap:Header";

NSString* const MITECPAssertionConsumerXPath = @"/soap:Envelope/soap:Header/ecp:Response/@AssertionConsumerServiceURL";
NSString* const MITECPRelayStateXPath = @"//ecp:RelayState";
NSString* const MITECPResponseConsumerXPath = @"/soap:Envelope/soap:Header/paos:Request/@responseConsumerURL";

NSString* const MITECPMIMEType = @"application/vnd.paos+xml";

NSString* const MITECPPAOSHeaderName = @"PAOS";
