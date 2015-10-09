#import <Cedar/Cedar.h>
#import "KSURLSessionClient.h"
#import "KSPromise.h"
#import "KSNetworkClientSpecURLProtocol.h"

using namespace Cedar::Matchers;
using namespace Cedar::Doubles;
using namespace Cedar::Doubles::Arguments;

SPEC_BEGIN(KSURLSessionClientSpec)

describe(@"KSURLSessionClient", ^{
    __block KSURLSessionClient *client;
    __block NSOperationQueue *queue;
    __block NSURLSession *session;

    beforeEach(^{
        queue = [[NSOperationQueue alloc] init];
    });

    context(@"when created without a session", ^{
        beforeEach(^{
            session = [NSURLSession sharedSession];
            [NSURLProtocol registerClass:[KSNetworkClientSpecURLProtocol class]];

            client = [[KSURLSessionClient alloc] init];
        });

        it(@"should use the right session", ^{
            client.session should be_same_instance_as([NSURLSession sharedSession]);
        });

        it(@"should resolve the promise on success", ^{
            NSURLRequest *request = [[NSURLRequest alloc] initWithURL:[NSURL URLWithString:@"pass://foo"]];
            KSPromise KS_GENERIC(KSNetworkResponse *) *promise = [client sendAsynchronousRequest:request queue:queue];
            __block NSOperationQueue *successQueue = nil;

            dispatch_semaphore_t sema = dispatch_semaphore_create(0);
            [promise then:^id(KSNetworkResponse *value) {
                successQueue = [NSOperationQueue currentQueue];
                dispatch_semaphore_signal(sema);
                return value;
            } error:^id(NSError *error) {
                dispatch_semaphore_signal(sema);
                return error;
            }];
            dispatch_semaphore_wait(sema, DISPATCH_TIME_FOREVER);

            NSString *value = [[NSString alloc] initWithData:[promise.value data] encoding:NSUTF8StringEncoding];
            value should equal(@"pass");

            successQueue should be_same_instance_as(queue);
        });

        it(@"should reject the promise on error", ^{
            NSURLRequest *request = [[NSURLRequest alloc] initWithURL:[NSURL URLWithString:@"fail://bar"]];
            KSPromise KS_GENERIC(KSNetworkResponse *) *promise = [client sendAsynchronousRequest:request queue:queue];
            __block NSOperationQueue *errorQueue = nil;

            dispatch_semaphore_t sema = dispatch_semaphore_create(0);
            [promise then:^id(KSNetworkResponse * value) {
                dispatch_semaphore_signal(sema);
                return value;
            } error:^id(NSError *error) {
                errorQueue = [NSOperationQueue currentQueue];
                dispatch_semaphore_signal(sema);
                return error;
            }];
            dispatch_semaphore_wait(sema, DISPATCH_TIME_FOREVER);

            promise.error.domain should equal(@"fail");
            errorQueue should be_same_instance_as(queue);
        });
    });

    context(@"when created with a provided session", ^{
        beforeEach(^{
            NSURLSessionConfiguration *configuration = [NSURLSessionConfiguration defaultSessionConfiguration];
            configuration.protocolClasses = @[[KSNetworkClientSpecURLProtocol class]];
            session = nice_fake_for([NSURLSession class]);

            client = [[KSURLSessionClient alloc] initWithURLSession:session];
        });

        it(@"should use the right session", ^{
            NSURLRequest *request = [[NSURLRequest alloc] initWithURL:[NSURL URLWithString:@"pass://foo"]];
            [client sendAsynchronousRequest:request queue:queue];

            session should have_received(@selector(dataTaskWithRequest:completionHandler:)).with(request, anything);
        });
    });
});

SPEC_END
