#import <Cedar/Cedar.h>
#import "KSNetworkClient.h"
#import "KSPromise.h"
#import <objc/runtime.h>

using namespace Cedar::Matchers;
using namespace Cedar::Doubles;


SPEC_BEGIN(KSNetworkClientSpec)

describe(@"KSNetworkClient", ^{
    __block KSNetworkClient *client;
    __block KSPromise *promise;
    __block void(^asyncRequestCallback)(NSURLResponse *, NSData *, NSError *);

    beforeEach(^{
        client = [[KSNetworkClient alloc] init];

        Class metaClass = objc_getMetaClass(NSStringFromClass([NSURLConnection class]).UTF8String);

        IMP fakeAsyncIMP = imp_implementationWithBlock(^(id me, NSURLRequest *r, NSOperationQueue *q, void(^callback)(NSURLResponse *, NSData *, NSError *)){
            asyncRequestCallback = [callback copy];
        });

        Method originalMethod = class_getClassMethod(metaClass, @selector(sendAsynchronousRequest:queue:completionHandler:));
        method_setImplementation(originalMethod, fakeAsyncIMP);

        NSURLRequest *request = [NSURLRequest new];
        promise = [client sendAsynchronousRequest:request queue:[NSOperationQueue mainQueue]];
    });

    it(@"should resolve the promise on success", ^{
        asyncRequestCallback([NSURLResponse new], [@"pass" dataUsingEncoding:NSUTF8StringEncoding], nil);

        NSString *value = [[NSString alloc] initWithData:[promise.value data] encoding:NSUTF8StringEncoding];
        value should equal(@"pass");
    });

    describe(@"with an error", ^{
        context(@"when there is an error and no data", ^{
            it(@"rejects with the unmodified error", ^{
                NSError *error = [NSError errorWithDomain:@"Spec" code:0 userInfo:@{}];
                asyncRequestCallback([NSURLResponse new], nil, error);

                promise.error should equal(error);
            });
        });

        context(@"when there is an error that has data", ^{
            it(@"rejects with an error that has a kKSNetworkClientErrorData entry in the userInfo", ^{
                NSError *error = [NSError errorWithDomain:@"Spec" code:0 userInfo:@{@"otherKey": @"otherValue"}];
                NSData *data = [@"fail" dataUsingEncoding:NSUTF8StringEncoding];
                asyncRequestCallback([NSURLResponse new], data, error);

                promise.error.domain should equal(error.domain);
                promise.error.code should equal(error.code);

                promise.error.userInfo[kKSNetworkClientErrorData] should equal(data);
                promise.error.userInfo[@"otherKey"] should equal(@"otherValue");
            });
        });

        context(@"when there is an error that has data and nil userInfo", ^{
            it(@"rejects with an error with a new userInfo dictionary containing kKSNetworkClientErrorData", ^{
                NSError *error = [NSError errorWithDomain:@"Spec" code:0 userInfo:nil];
                NSData *data = [@"fail" dataUsingEncoding:NSUTF8StringEncoding];
                asyncRequestCallback([NSURLResponse new], data, error);

                promise.error.domain should equal(error.domain);
                promise.error.code should equal(error.code);

                promise.error.userInfo[kKSNetworkClientErrorData] should equal(data);
            });
        });
    });
});

SPEC_END
