#import "KSNetworkClientSpecURLProtocol.h"

@implementation KSNetworkClientSpecURLProtocol

+ (BOOL)canInitWithRequest:(NSURLRequest *)request {
    return [@[@"pass", @"fail"] containsObject:request.URL.scheme];
}

+ (NSURLRequest *)canonicalRequestForRequest:(NSURLRequest *)request {
    return request;
}

+ (BOOL)requestIsCacheEquivalent:(NSURLRequest *)a toRequest:(NSURLRequest *)b {
    return NO;
}

- (void)startLoading {
    if ([self.request.URL.scheme isEqualToString:@"pass"]) {
        NSURLResponse *response = [[NSURLResponse alloc] init];
        [self.client URLProtocol:self didReceiveResponse:response cacheStoragePolicy:NSURLCacheStorageNotAllowed];
        [self.client URLProtocol:self didLoadData:[@"pass" dataUsingEncoding:NSUTF8StringEncoding]];
        [self.client URLProtocolDidFinishLoading:self];
    } else {
        [self.client URLProtocol:self didFailWithError:[NSError errorWithDomain:@"fail" code:1 userInfo:nil]];
    }
}

- (void)stopLoading {}
@end