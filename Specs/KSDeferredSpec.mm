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

        context(@"when the array of joined promises is empty", ^{
            beforeEach(^{
                joinedPromise = [KSPromise when:@[]];

                fulfilled = rejected = NO;

                [joinedPromise then:^id(id value) {
                    fulfilled = YES;
                    return value;
                } error:^id(NSError *error) {
                    rejected = YES;
                    return error;
                }];
            });

            it(@"should immediately resolve", ^{
                fulfilled should be_truthy;
                rejected should_not be_truthy;
            });

            it(@"should resolve with an empty array", ^{
                joinedPromise.value should equal(@[]);
            });
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

            context(@"when the first promise is resolved", ^{
                beforeEach(^{
                    [deferred resolveWithValue:@"SUCCESS1"];
                });
                
                it(@"should not resolve the joined promise", ^{
                    fulfilled should_not be_truthy;
                    rejected should_not be_truthy;
                });
                
                context(@"when both promises are resolved", ^{
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

                context(@"when both promises are resolved, one without a value", ^{
                    beforeEach(^{
                        [deferred2 resolveWithValue:nil];
                    });

                    it(@"should coerce the nil value to NSNull", ^{
                        [joinedPromise.value objectAtIndex:1] should equal([NSNull null]);
                    });
                });

                context(@"when a promise is rejected and all joined promises have been fulfilled", ^{
                    beforeEach(^{
                        [deferred2 rejectWithError:[NSError errorWithDomain:@"MyError" code:123 userInfo:nil]];
                    });
                    
                    it(@"should call the rejected callback", ^{
                        rejected should be_truthy;
                    });
                    
                    it(@"should be able to read the rejected errors of the joined promises", ^{
                        joinedPromise.error.domain should equal(KSPromiseWhenErrorDomain);
                        NSArray *errors = [joinedPromise.error.userInfo objectForKey:KSPromiseWhenErrorErrorsKey];
                        errors.count should equal(1);
                        [[errors lastObject] domain] should equal(@"MyError");
                    });

                    it(@"should be able to read the resolved values of the joined promises", ^{
                        joinedPromise.error.domain should equal(KSPromiseWhenErrorDomain);
                        NSArray *values = [joinedPromise.error.userInfo objectForKey:KSPromiseWhenErrorValuesKey];
                        values.count should equal(1);
                        values.lastObject should equal(@"SUCCESS1");
                    });
                });

              context(@"when a promise is rejected without an error and all joined promises have been fulfilled", ^{
                    beforeEach(^{
                        [deferred2 rejectWithError:nil];
                    });

                    it(@"should insert a null object into the joined promises error list", ^{
                        NSArray *errors = joinedPromise.error.userInfo[KSPromiseWhenErrorErrorsKey];
                        [errors lastObject] should equal([NSNull null]);
                    });
                });

                it(@"should be marked as fulfilled", ^{
                    promise.fulfilled should be_truthy;
                });
            });

            context(@"when the first promise is rejected", ^{
                beforeEach(^{
                    [deferred2 rejectWithError:[NSError errorWithDomain:@"MyError" code:123 userInfo:nil]];
                });
                
                it(@"should not reject the joined promise", ^{
                    fulfilled should_not be_truthy;
                    rejected should_not be_truthy;
                });

                it(@"should be marked as rejected", ^{
                    promise2.rejected should be_truthy;
                });
            });
        });

        context(@"when the first promise is resolved before joined", ^{
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
        
        context(@"when the first promise is rejected before joined", ^{
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

        context(@"when all promises are resolved before joined", ^{
            beforeEach(^{
                [deferred resolveWithValue:@"SUCCESS1"];
                [deferred2 resolveWithValue:@"SUCCESS2"];

                joinedPromise = [KSPromise when:@[promise, promise2]];

                fulfilled = rejected = NO;

                [joinedPromise then:^id(id value) {
                    fulfilled = YES;
                    return value;
                } error:^id(NSError *error) {
                    rejected = YES;
                    return error;
                }];
            });

            it(@"should immediately resolve", ^{
                fulfilled should be_truthy;
                [joinedPromise.value objectAtIndex:0] should equal(@"SUCCESS1");
                [joinedPromise.value objectAtIndex:1] should equal(@"SUCCESS2");
            });
        });

        context(@"when all promises are resolved or rejected before joined", ^{
            beforeEach(^{
                [deferred resolveWithValue:@"SUCCESS"];
                [deferred2 rejectWithError:[NSError errorWithDomain:@"MyError" code:123 userInfo:nil]];

                joinedPromise = [KSPromise when:@[promise, promise2]];

                fulfilled = rejected = NO;

                [joinedPromise then:^id(id value) {
                    fulfilled = YES;
                    return value;
                } error:^id(NSError *error) {
                    rejected = YES;
                    return error;
                }];
            });

            it(@"should immediately reject", ^{
                fulfilled should_not be_truthy;
                rejected should be_truthy;

                joinedPromise.error.domain should equal(KSPromiseWhenErrorDomain);
                NSArray *errors = joinedPromise.error.userInfo[KSPromiseWhenErrorErrorsKey];
                errors.count should equal(1);
                [errors.lastObject domain] should equal(@"MyError");

                joinedPromise.error.domain should equal(KSPromiseWhenErrorDomain);
                NSArray *values = joinedPromise.error.userInfo[KSPromiseWhenErrorValuesKey];
                values.count should equal(1);
                values.lastObject should equal(@"SUCCESS");
            });
        });
    });
});

SPEC_END
