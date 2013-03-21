#import <Cedar/SpecHelper.h>
#import "KSNetworkClient.h"
#import "KSPromise.h"

using namespace Cedar::Matchers;
using namespace Cedar::Doubles;

@interface KSNetworkClientSpecURLProtocol : NSURLProtocol
@end

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


SPEC_BEGIN(KSNetworkClientSpec)

describe(@"KSNetworkClient", ^{
    __block KSNetworkClient *client;
    __block NSOperationQueue *queue;

    beforeEach(^{
        client = [[KSNetworkClient alloc] init];
        queue = [[NSOperationQueue alloc] init];
        [NSURLProtocol registerClass:[KSNetworkClientSpecURLProtocol class]];
    });

    it(@"should resolve the promise on success", ^{
        NSURLRequest *request = [[NSURLRequest alloc] initWithURL:[NSURL URLWithString:@"pass://foo"]];
        KSPromise *promise = [client sendAsynchronousRequest:request queue:queue];
        dispatch_semaphore_t sema = dispatch_semaphore_create(0);
        [promise then:^id(id value) {
            dispatch_semaphore_signal(sema);
            return value;
        } error:^id(NSError *error) {
            dispatch_semaphore_signal(sema);
            return error;
        }];
        dispatch_semaphore_wait(sema, DISPATCH_TIME_FOREVER);
        NSString *value = [[NSString alloc] initWithData:[promise.value data] encoding:NSUTF8StringEncoding];
        value should equal(@"pass");
    });

    it(@"should reject the promise on error", ^{
        NSURLRequest *request = [[NSURLRequest alloc] initWithURL:[NSURL URLWithString:@"fail://bar"]];
        KSPromise *promise = [client sendAsynchronousRequest:request queue:queue];
        dispatch_semaphore_t sema = dispatch_semaphore_create(0);
        [promise then:^id(id value) {
            dispatch_semaphore_signal(sema);
            return value;
        } error:^id(NSError *error) {
            dispatch_semaphore_signal(sema);
            return error;
        }];
        dispatch_semaphore_wait(sema, DISPATCH_TIME_FOREVER);
        promise.error.domain should equal(@"fail");
    });
});

SPEC_END
