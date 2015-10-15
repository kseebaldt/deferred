#import <Cedar/Cedar.h>
#import "KSNetworkClient.h"
#import "KSPromise.h"
#import "KSNetworkClientSpecURLProtocol.h"

using namespace Cedar::Matchers;
using namespace Cedar::Doubles;

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
        KSPromise KS_GENERIC(KSNetworkResponse *) *promise = [client sendAsynchronousRequest:request queue:queue];
        dispatch_semaphore_t sema = dispatch_semaphore_create(0);
        [promise then:^id(KSNetworkResponse *value) {
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
        KSPromise KS_GENERIC(KSNetworkResponse *) *promise = [client sendAsynchronousRequest:request queue:queue];
        dispatch_semaphore_t sema = dispatch_semaphore_create(0);
        [promise then:^id(KSNetworkResponse *value) {
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
