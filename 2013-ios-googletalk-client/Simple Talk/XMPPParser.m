//
//  XMPPParser.m
//  GTell
//
//  Created by Joel Edström on 3/16/13.
//  Copyright (c) 2013 Joel Edström. All rights reserved.
//

#import "XMPPParser.h"
#import "WritableBufferedInputStream.h"






@interface InternalXMLNode : NSObject
@property (nonatomic) NSString* name;
@property (nonatomic) NSMutableArray* children;
@property (nonatomic) NSDictionary* attributes;
@property (nonatomic) NSMutableString* text;
- (XMLNode*)toXMLNode;
@end

@implementation InternalXMLNode
- (XMLNode*)toXMLNode {
    
    NSMutableArray* c = [NSMutableArray new];
    
    for (InternalXMLNode* n in _children) {
        [c addObject:[n toXMLNode]];
    }
    
    
    return [[XMLNode alloc] initWithName:_name
                                children:[c copy]
                              attributes:_attributes
                                    text:[_text copy]];
}
@end

#pragma mark - node stack

@interface NSMutableArray(Stack)
- (void)push:(id)object;
- (InternalXMLNode*)pop;
- (InternalXMLNode*)head;
@end

@implementation NSMutableArray(Stack)
- (void)push:(id)object {
    [self addObject:object];
}
- (id)pop {
    id r = [self lastObject];
    if (r) [self removeLastObject];
    return r;
}
- (id)head {
    return [self lastObject];
}
@end

#pragma mark - XMPPParser

@interface XMPPParser() <NSXMLParserDelegate>
@property (nonatomic) XMLNode* root;

@end

@implementation XMPPParser {
    WritableBufferedInputStream* _stream;
    NSXMLParser* _parser;
    BOOL _hasRoot;
    XMLNode* _current;
    NSMutableArray* _stack;
    __weak id <XMPPParserDelegate> _delegate;
    dispatch_queue_t _delegateQueue;
}
- (id)initWithDelegate:(id <XMPPParserDelegate>)delegate
           delegateQueue:(dispatch_queue_t)queue
{
    self = [super init];
    if (self) {
        _delegate = delegate;
        _delegateQueue = queue;
        _stream = [WritableBufferedInputStream new];
        _parser = [[NSXMLParser alloc] initWithStream:_stream];
        _parser.delegate = self;
        _stack = [NSMutableArray new];
        [NSThread detachNewThreadSelector:@selector(parseThread)
                                 toTarget:self
                               withObject:nil];
    }
    return self;
}


- (void)parseThread {
    [_parser parse];
    NSLog(@"NSXMLParser thread died");
}

- (void)parseData:(NSData*)data {
    [_stream write:data];
}

- (void)abort {
    [_stream finish];
}

- (void)nodeFinished:(InternalXMLNode*)node {
    XMLNode* n = [node toXMLNode];
    dispatch_async(_delegateQueue, ^{
        [_delegate foundStanza:n];
    });
}

- (void)streamFinished:(NSError*)e {
    dispatch_async(_delegateQueue, ^{
        [_delegate foundEnd:e];
    });
}

- (void)parserDidEndDocument:(NSXMLParser *)parser {
    [self streamFinished:nil];
    [self abort];
}

- (void)parser:(NSXMLParser *)parser parseErrorOccurred:(NSError *)parseError {
    
    // ignore XML_WAR_NS_URI_RELATIVE caused by vCards
    // (cant disable XML_PARSE_PEDANTIC with NSXMLParser)
    if (parseError.code == 100)
        return;  
    
    [self streamFinished:parseError];
    [self abort];
}

- (void)parser:(NSXMLParser *)parser didStartElement:(NSString *)elementName namespaceURI:(NSString *)namespaceURI qualifiedName:(NSString *)qName attributes:(NSDictionary *)attributeDict {
    //NSLog(@"parser:didStartElement...");
    
    if (_hasRoot) {
        InternalXMLNode* n = [InternalXMLNode new];
        
        n.name = elementName;
        n.children = [NSMutableArray new];
        n.attributes = attributeDict;
        n.text = [NSMutableString new];
        
        [_stack.head.children addObject:n];
        
        [_stack push:n];
        
    } else {
        self.root = [[XMLNode alloc] initWithName:elementName
                                         children:nil
                                       attributes:attributeDict
                                             text:nil];
        _hasRoot = YES;
        
        dispatch_async(_delegateQueue, ^{
            [_delegate foundRoot];
        });
    }
}

- (void)parser:(NSXMLParser *)parser foundCharacters:(NSString *)string {
    //NSLog(@"parser:foundCharacters: %@", string);
    
    if (_stack.head) {
        [_stack.head.text appendString:string];
    }
}

- (void)parser:(NSXMLParser *)parser didEndElement:(NSString *)elementName namespaceURI:(NSString *)namespaceURI qualifiedName:(NSString *)qName {
    //NSLog(@"parser:didEndElement...");
    
    if (_stack.head) {
    
        InternalXMLNode* node = [_stack pop];
    
        // we're back to just one level above root
        if (!_stack.head) {
            [self nodeFinished:node];
        }
    } else {
        // we just got the stream(root) end
    }
}
@end
