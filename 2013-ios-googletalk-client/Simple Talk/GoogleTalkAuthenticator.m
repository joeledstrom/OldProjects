//
//  GoogleTalkAuthenticator.m
//  GTell
//
//  Created by Joel Edström on 3/18/13.
//  Copyright (c) 2013 Joel Edström. All rights reserved.
//

#import "GoogleTalkAuthenticator.h"
#import "Base64.h"
#import "XMPPStream.h"
#import "XMPPParser.h"
#import "Utils.h"



@interface XMLNode(Extras)
- (BOOL)hasStartTLSFeature;
- (BOOL)isProceedXMPPTLS;
@end


@implementation XMLNode(Extras)
- (BOOL)hasStartTLSFeature {
    BOOL ret = YES;
    
    ret = [self.name isEqual:@"stream:features"];
    
    ret = [self childWithName:@"starttls"] == nil ? NO : YES;
    
    return ret;
}
- (BOOL)isProceedXMPPTLS {
    BOOL ret = YES;
    
    ret = [self.name isEqual:@"proceed"];
    
    NSString* xmlns = self.attributes[@"xmlns"];
    ret = [xmlns rangeOfString:@"tls"].length > 0;   //contains
    
    return ret;
}
@end







@implementation GoogleTalkAuthenticator {
    XMPPStreamRemote* _stream;
    NSString* _account;
    NSString* _accessToken;
    
}

- (id)initWithAccount:(NSString*)account
          accessToken:(NSString*)accessToken {
    
    self = [super init];
    if (self) {
        _account = account;
        _accessToken = accessToken;
    }
    return self;
}

- (void)startWithRemote:(XMPPStreamRemote*)remote {
    _stream = remote;
    [self sendStreamHandshake];
}
- (void)stanzaReceived:(XMLNode*)node {
    
    
    if (node.hasStartTLSFeature) {
        static NSString* startTLS = @"<starttls xmlns='urn:ietf:params:xml:ns:xmpp-tls'/>";
        [_stream sendData:startTLS];
    }
    
    if (node.isProceedXMPPTLS) {
        NSLog(@"startingTLS");
        [_stream newStream];
        [_stream startTLS];
        [self sendStreamHandshake];
    }
    
    if (!node.hasStartTLSFeature && [node.name isEqual:@"stream:features"] && ![[node.children[0] name] isEqual:@"bind"]) {
        [self sendAuth];
    }
    
    if ([node.name isEqual:@"success"]  && [node.attributes[@"xmlns"] isEqual:@"urn:ietf:params:xml:ns:xmpp-sasl"]) {
        NSLog(@"auth success");
        [_stream newStream];
        [self sendStreamHandshake];
    }
    
    if ([node.name isEqual:@"failure"] && [node.attributes[@"xmlns"] isEqual:@"urn:ietf:params:xml:ns:xmpp-sasl"]) {
        [_stream sendModuleEvent:kModuleEventAuthenticationFailure];
    }
    
    if ([node.name isEqual:@"stream:features"] &&  [[node.children[0] name] isEqual:@"bind"]) {
        static NSString* bindReq = @"<iq type='set' id='bind_1'><bind xmlns='urn:ietf:params:xml:ns:xmpp-bind'/></iq>";
        [_stream sendData:bindReq];
    }
    
    if ([node.name isEqual:@"iq"] && node.children.count > 0 && [[node.children[0] name] isEqual:@"bind"]) {
        static NSString* sess = @"<iq to='talk.google.com' type='set' id='sess_1'><session xmlns='urn:ietf:params:xml:ns:xmpp-session'/></iq>";
        [_stream sendData:sess];
        
    }
    
    if ([node.attributes[@"id"] isEqual:@"sess_1"]) {
        [_stream sendModuleEvent:kModuleEventAuthenticationComplete];
    }

}

- (void)sendStreamHandshake {
    // TODO: investigate why it has to be 'talk.google.com ', also google apps support?
    // trying gmail.com
    
    //static NSString* handshakeBegin = @"<stream:stream to='gmail.com' version='1.0' xmlns='jabber:client' xmlns:stream='http://etherx.jabber.org/streams'>";
    static NSString* handshakeBegin = @"<stream:stream to='talk.google.com ' version='1.0' xmlns='jabber:client' xmlns:stream='http://etherx.jabber.org/streams'>";
    [_stream sendData:handshakeBegin];
}

- (void)sendAuth {
    // base64("\0" + user_name + "\0" + oauth_token)
    
    
    NSString* base64 = [[NSString stringWithFormat:@"\0%@\0%@", _account, _accessToken] toBase64];
    
    static NSString* authBase = @"<auth xmlns='urn:ietf:params:xml:ns:xmpp-sasl' mechanism='X-OAUTH2' auth:service='oauth2' xmlns:auth='http://www.google.com/talk/protocol/auth'>%@</auth>";
    
    NSString* auth = [NSString stringWithFormat:authBase, base64];
    [_stream sendData:auth];
}

@end
