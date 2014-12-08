#import "KSDeferred.h"

using namespace Cedar::Matchers;
using namespace Cedar::Doubles;

SPEC_BEGIN(KSDeferredWaitForValueSpec)

describe(@"KSDeferredWaitForValue", ^{
    __block KSPromise *promise;
    __block KSDeferred *deferred;

    beforeEach(^{
        deferred = [KSDeferred defer];
        promise = deferred.promise;
    });

    describe(@"wait for value", ^{
        it(@"should return the value immediately if promise is already fulfilled", ^{
            [deferred resolveWithValue:@"DONE"];
            [promise waitForValue] should equal(@"DONE");
        });

        it(@"should return the value when promise is fulfilled", ^{
            dispatch_queue_t q = dispatch_queue_create("test", DISPATCH_QUEUE_SERIAL);
            dispatch_after(dispatch_time(DISPATCH_TIME_NOW, 0.1 * NSEC_PER_SEC), q, ^{
                [deferred resolveWithValue:@"DONE"];
            });
            [promise waitForValue] should equal(@"DONE");
        });

        it(@"should continue to return the value when promise is fulfilled", ^{
            dispatch_queue_t q = dispatch_queue_create("test", DISPATCH_QUEUE_SERIAL);
            dispatch_after(dispatch_time(DISPATCH_TIME_NOW, 0.1 * NSEC_PER_SEC), q, ^{
                [deferred resolveWithValue:@"DONE"];
            });
            [promise waitForValue] should equal(@"DONE");
            [promise waitForValue] should equal(@"DONE");
        });

        it(@"should return a timeout error if the promise is not fulfilled in time", ^{
            [promise waitForValueWithTimeout:0.1] should equal([NSError errorWithDomain:@"KSPromise" code:1 userInfo:@{NSLocalizedDescriptionKey: @"Timeout exceeded while waiting for value"}]);
        });

        it(@"should return the error when promise is rejected", ^{
            NSError *error = [NSError errorWithDomain:@"testError" code:123 userInfo:nil];
            [deferred rejectWithError:error];
            [promise waitForValue] should equal(error);
        });
    });
});

SPEC_END
