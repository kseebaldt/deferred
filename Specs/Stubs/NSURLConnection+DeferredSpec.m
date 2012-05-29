#import <objc/runtime.h>

@interface NSURLConnectionSpecDelegate : NSObject <NSURLConnectionDelegate>
@property (nonatomic, strong) NSURLResponse *response;
@property (nonatomic, strong) NSMutableData *data;
@property (nonatomic, copy) void (^handler)(NSURLResponse*, NSData*, NSError*);
- (id)initWithCompletionHandler:(void (^)(NSURLResponse*, NSData*, NSError*)) handler;
@end


@implementation NSURLConnectionSpecDelegate
@synthesize data = _data, response = _response, handler = _handler;

- (id)initWithCompletionHandler:(void (^)(NSURLResponse*, NSData*, NSError*)) handler {
    if (self = [super init]) {
        self.handler = handler;
    }
    return self;
}

- (void)connection:(NSURLConnection *)connection didReceiveResponse:(NSURLResponse *)response {
    self.response = response;
    self.data = [NSMutableData data];
}

- (void)connection:(NSURLConnection *)connection didReceiveData:(NSData *)data {
    [self.data appendData:data];
}

- (void)connectionDidFinishLoading:(NSURLConnection *)connection {
    self.handler(self.response, self.data, nil);
}

- (void)connection:(NSURLConnection *)connection didFailWithError:(NSError *)error {
    self.handler(nil, nil, error);    
}

@end

@implementation NSURLConnection (DeferredSpec)

+ (void)sendAsynchronousRequest:(NSURLRequest *)request
                          queue:(NSOperationQueue*) queue
              completionHandler:(void (^)(NSURLResponse*, NSData*, NSError*)) handler {
    
    NSURLConnectionSpecDelegate *delegate = [[NSURLConnectionSpecDelegate alloc] initWithCompletionHandler:handler];
    NSURLConnection *conn = [NSURLConnection connectionWithRequest:request delegate:delegate];
    objc_setAssociatedObject(conn, @"specDelegate", delegate, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}

@end