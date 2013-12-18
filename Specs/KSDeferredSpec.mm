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

    describe(@"when", ^ {
        __block KSPromise *promise2;
        __block KSDeferred *deferred2;
        __block KSPromise *joinedPromise;
        __block BOOL fulfilled;
        __block BOOL rejected;

        beforeEach(^{
            deferred2 = [KSDeferred defer];
            promise2 = deferred2.promise;
        });

        context(@"when joined promises get resolved or rejected after join", ^{
            beforeEach(^{
                joinedPromise = [KSPromise when:[NSArray arrayWithObjects:promise, promise2, nil]];
                
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

                it(@"should be marked as fulfilled", ^{
                    joinedPromise.fulfilled should be_truthy;
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

                it(@"should be marked as rejected", ^{
                    joinedPromise.rejected should be_truthy;
                });
            });
        });

        describe(@"when the first promise is resolved before joined", ^{
            beforeEach(^{
                [deferred resolveWithValue:@"SUCCESS1"];
                joinedPromise = [KSPromise when:[NSArray arrayWithObjects:promise, promise2, nil]];
                
                fulfilled = rejected = NO;
                
                [joinedPromise then:^id(id value) {
                    fulfilled = YES;
                    return value;
                } error:^id(NSError *error) {
                    rejected = YES;
                    return error;
                }];
            });
            
            it(@"should not resolve joinedPromise", ^{
                fulfilled should_not be_truthy;
                rejected should_not be_truthy;
            });
        });
        
        describe(@"when the first promise is rejected before joined", ^{
            beforeEach(^{
                [deferred rejectWithError:[NSError errorWithDomain:@"MyError" code:123 userInfo:nil]];
                joinedPromise = [KSPromise when:[NSArray arrayWithObjects:promise, promise2, nil]];
                
                fulfilled = rejected = NO;
                
                [joinedPromise then:^id(id value) {
                    fulfilled = YES;
                    return value;
                } error:^id(NSError *error) {
                    rejected = YES;
                    return error;
                }];
            });
            
            it(@"should not resolve joinedPromise", ^{
                fulfilled should_not be_truthy;
                rejected should_not be_truthy;
            });
        });
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
            dispatch_queue_t q = dispatch_queue_create("test", DISPATCH_QUEUE_SERIAL);
            dispatch_after(dispatch_time(DISPATCH_TIME_NOW, 0.2 * NSEC_PER_SEC), q, ^{
                [deferred resolveWithValue:@"DONE"];
            });

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
