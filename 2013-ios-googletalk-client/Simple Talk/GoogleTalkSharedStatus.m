//
//  GoogleTalkPresence.m
//  GTell
//
//  Created by Joel Edström on 3/18/13.
//  Copyright (c) 2013 Joel Edström. All rights reserved.
//


#import "XMLNode+XMPP.h"
#import "XMPPParser.h"
#import "Utils.h"
#import "GoogleTalkSharedStatus.h"





@implementation GoogleTalkStatusList @end






@implementation GoogleTalkSharedStatus {
    XMPPStreamRemote* _streamRemote;
    NSString* _account;
    NSInteger _status_max;
    NSInteger _status_list_max;
    NSInteger _status_list_contents_max;
    NSInteger _status_min_ver;
    
    NSString* _currentStatus;
    NSString* _currentShow;
    
    NSArray* _statusLists;
    
    BOOL _invisible;
}

- (id)initWithAccount:(NSString*)account {
    self = [super init];
    if (self) {
        _account = account;
    }
    return self;
}
- (void)startWithRemote:(XMPPStreamRemote*)remote {
    _streamRemote = remote;
}

- (void)moduleEventRecevied:(NSString *)event {
    if ([event isEqual:kModuleEventAuthenticationComplete]) {
        static NSString* initialRequest = @"<iq type='get' to='%@' id='ss-1' ><query xmlns='google:shared-status' version='2'/></iq>";
        
        
        [_streamRemote sendData:[NSString stringWithFormat:initialRequest, _account]];
    }
}





- (void)iqReceived:(XMLNode*)iq {
    if ([iq.type isEqual:@"result"]) {
        XMLNode* query = [iq childWithName:@"query"];
        if ([query.attributes[@"xmlns"] isEqual:@"google:shared-status"]) {
            _status_max = [query.attributes[@"status-max"] integerValue];
            _status_list_max = [query.attributes[@"status-list-max"] integerValue];
            _status_list_contents_max = [query.attributes[@"status-list-contents-max"] integerValue];
            
            
            [self readFromQuery:query];
            
            [self sendActivePresence];
            
        }
    }
    
    if ([iq.type isEqual:@"set"]) {
        XMLNode* query = [iq childWithName:@"query"];
        if ([query.attributes[@"xmlns"] isEqual:@"google:shared-status"]) {
            [self readFromQuery:query];
        }
    }
}

- (void)readFromQuery:(XMLNode*)query {
    _status_min_ver = [query.attributes[@"status-min-ver"] integerValue];
    
    _currentStatus = [query childWithName:@"status"].text;
    _currentShow = [query childWithName:@"show"].text;
    
    
    _statusLists = [[query childrenWithName:@"status-list"] map:^id(XMLNode* listNode) {
        GoogleTalkStatusList* l = [GoogleTalkStatusList new];
        l.show = listNode.attributes[@"show"];
        l.statuses = [[listNode childrenWithName:@"status"] map:^id(XMLNode* x) {
            return x.text;
        }];
        
        return l;
    }];
    
    
    _invisible =  [[query childWithName:@"invisible"].attributes[@"value"] isEqual:@"true"] ? YES : FALSE;
}

- (void)sendActivePresence {
    [_streamRemote sendData:@"<presence />"];
}

- (void)sendIdlePresence {
    [_streamRemote sendData:@"<presence><show>away</show></presence>"];
}
@end
