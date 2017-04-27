//
//  XMLNode.m
//  Simple Talk
//
//  Created by Joel Edström on 3/28/13.
//  Copyright (c) 2013 Joel Edström. All rights reserved.
//

#import "XMLNode.h"
#import "Utils.h"
#import "DDLog.h"

static const int ddLogLevel = LOG_LEVEL_ERROR;




@interface XMLParser : NSObject <NSXMLParserDelegate>
@property (nonatomic) XMLNode* parsedNode;
@end

@implementation XMLParser {
    NSXMLParser* _parser;
    NSMutableArray* _stack;
    
}

- (id)initWithData:(NSData*)data
{
    self = [super init];
    if (self) {
        _parser = [[NSXMLParser alloc] initWithData:data];
        _parser.delegate = self;
        _stack = [NSMutableArray new];
        [_parser parse];
        
    }
    return self;
}

- (void)parserDidEndDocument:(NSXMLParser *)parser {
    DDLogVerbose(@"Parser found end of document");
}

- (void)parser:(NSXMLParser *)parser parseErrorOccurred:(NSError *)parseError {
    
    DDLogInfo(@"Parse Error: %@", parseError);
    if (parseError.code != 100)
        [parser abortParsing];
    else
        DDLogVerbose(@"XMLParser: XML_WAR_NS_URI_RELATIVE");
}

- (void)parser:(NSXMLParser *)parser didStartElement:(NSString *)elementName namespaceURI:(NSString *)namespaceURI qualifiedName:(NSString *)qName attributes:(NSDictionary *)attributeDict {
    
    XMLNode* n = [[XMLNode alloc] initWithName:elementName
                                      children:[NSMutableArray new]
                                    attributes:attributeDict
                                          text:[NSMutableString new]];
    
    NSMutableArray* children = (NSMutableArray*)[_stack.head children];
    [children addObject:n];
    
    [_stack push:n];
    
    
}

- (void)parser:(NSXMLParser *)parser foundCharacters:(NSString *)string {
    
    if (_stack.head) {
        NSMutableString* text = (NSMutableString*)[_stack.head text];
        [text appendString:string];
    }
}

- (void)parser:(NSXMLParser *)parser didEndElement:(NSString *)elementName namespaceURI:(NSString *)namespaceURI qualifiedName:(NSString *)qName {

    if (_stack.head) {
        XMLNode* node = [_stack pop];
        if (!_stack.head) {
            self.parsedNode = node;
        }
    }
        
}


@end









@implementation XMLNode
+ (XMLNode*)parseData:(NSData*)data {
    return [[XMLParser alloc] initWithData:data].parsedNode;
}

- (id)initWithName:(NSString*)name
          children:(NSArray*)children
        attributes:(NSDictionary*)attributes
              text:(NSString*)text
{
    self = [super init];
    if (self) {
        _name = name;
        _children = children;
        _attributes = attributes;
        _text = text;
    }
    return self;
}

- (void)appendNodeTo:(NSMutableString*)str level:(int)level {
    NSMutableString* spacer = [NSMutableString new];
    for (int i = 0; i < level; i++) {
        [spacer appendString:@"  "];
    }
    
    [str appendString:spacer];
    
    [str appendFormat:@"<%@", self.name];
    for (NSString* key in self.attributes.keyEnumerator) {
        [str appendFormat:@" %@='%@'", key, self.attributes[key]];
    }
    [str appendString:@">\n"];
    
    if (self.text && ![self.text isEqual:@""]) {
        [str appendString:spacer];
        [str appendString:spacer];
        [str appendString:self.text];
        [str appendString:@"\n"];
    }
    
    for (XMLNode* node in self.children) {
        [node appendNodeTo:str level:level + 1];
    }
    
    [str appendString:spacer];
    [str appendFormat:@"</%@>\n", self.name];
    
    
}

- (NSString *)description {
    NSMutableString* str = [NSMutableString string];
    
    [self appendNodeTo:str level:0];
    
    return [NSString stringWithString:str];
}
@end



@implementation XMLNode(Useful)
- (XMLNode*)childWithName:(NSString*)name {
    return [self childrenWithName:name].first;
}
- (NSArray*)childrenWithName:(NSString*)name {
    return [self.children filter:^BOOL(XMLNode* x) {
        return [x.name isEqual:name] ? YES : NO;
    }];
}

- (NSArray*)childrenMatchingFilter:(BOOL (^)(XMLNode* x))filter {
    return [self.children filter:^BOOL(XMLNode* x) {
        return filter(x);
    }];
}

@end

