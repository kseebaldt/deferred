#import <Cedar/SpecHelper.h>

#import "KSPromise.h"
#import "KSDeferred.h"

using namespace Cedar::Matchers;

SPEC_BEGIN(KSDeferredSpec)

describe(@"KSDeferred", ^{
    __block KSPromise *promise;
    __block KSDeferred *deferred;

    beforeEach(^{
        deferred = [KSDeferred defer];
        promise = deferred.promise;
    });

    it(@"should be created", ^{
        deferred should_not be_nil;
    });

    it(@"should have a promise", ^{
        promise should_not be_nil;
    });

    describe(@"joining", ^ {
        __block KSPromise *promise2;
        __block KSDeferred *deferred2;
        __block KSPromise *joinedPromise;
        __block BOOL fulfilled;
        __block BOOL rejected;

        beforeEach(^{
            deferred2 = [KSDeferred defer];
            promise2 = deferred2.promise;
            joinedPromise = [KSPromise join:[NSArray arrayWithObjects:promise, promise2, nil]];

            fulfilled = rejected = NO;

            [joinedPromise then:^id(id value) {
                fulfilled = YES;
                return value;
            } error:^id(NSError *error) {
                rejected = YES;
                return error;
            }];
        });

        describe(@"when the first promise is resolved", ^{
            beforeEach(^{
                [deferred resolveWithValue:@"SUCCESS1"];
            });

            it(@"should not resolve the joined promise", ^{
                fulfilled should_not be_truthy;
                rejected should_not be_truthy;
            });

            describe(@"when both promises are resolved", ^{
                beforeEach(^{
                    [deferred2 resolveWithValue:@"SUCCESS2"];
                });

                it(@"should call the resolved callback", ^{
                    fulfilled should be_truthy;
                });

                it(@"should be able to read the resolved values of the joined promises", ^{
                    [joinedPromise.value objectAtIndex:0] should equal(@"SUCCESS1");
                    [joinedPromise.value objectAtIndex:1] should equal(@"SUCCESS2");
                });

            });

            describe(@"when a promise is rejected and all joined promises have been fulfilled", ^{
                beforeEach(^{
                    [deferred2 rejectWithError:[NSError errorWithDomain:@"MyError" code:123 userInfo:nil]];
                });

                it(@"should call the rejected callback", ^{
                    rejected should be_truthy;
                });

                it(@"should be able to read the resolved values of the joined promises", ^{
                    joinedPromise.error.domain should equal(@"KSPromiseJoinError");
                    NSArray *errors = [joinedPromise.error.userInfo objectForKey:@"errors"];
                    errors.count should equal(1);
                    [[errors lastObject] domain] should equal(@"MyError");
                });

            });
        });

        describe(@"when the first promise is rejected", ^{
            beforeEach(^{
                [deferred2 rejectWithError:[NSError errorWithDomain:@"MyError" code:123 userInfo:nil]];
            });

            it(@"should not reject the joined promise", ^{
                fulfilled should_not be_truthy;
                rejected should_not be_truthy;
            });
        });
    });
});

SPEC_END
