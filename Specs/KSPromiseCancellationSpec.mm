#import <Cedar/Cedar.h>
#import "KSDeferred.h"
#import "KSPromise.h"

using namespace Cedar::Matchers;
using namespace Cedar::Doubles;

SPEC_BEGIN(KSPromiseCancellationSpec)

describe(@"KSPromiseCancellation", ^{
    __block KSDeferred *deferred;
    __block KSPromise *promise;

    beforeEach(^{
        deferred = [KSDeferred defer];
        promise = deferred.promise;
    });

    describe(@"Canceling a promise", ^{
        __block BOOL cancelBlockCalled;
        __block id thenBlockCalledWithValue;
        __block NSError *errorBlockCalledWithError;
        __block KSPromise *childPromise;

        beforeEach(^{
            cancelBlockCalled = NO;
            thenBlockCalledWithValue = nil;
            errorBlockCalledWithError = nil;
            [deferred whenCancelled:^{
                cancelBlockCalled = YES;
            }]  ;

            childPromise = [promise then:^id(id value) {
                thenBlockCalledWithValue = value;
                return value;
            } error:^id(NSError *error) {
                errorBlockCalledWithError = error;
                return error;
            }];
        });

        context(@"for a single promise", ^{
            beforeEach(^{
                [promise cancel];
            });

            it(@"should call the cancel block of the promise's deferred", ^{
                cancelBlockCalled should be_truthy;
            });

            it(@"should not fire the promise's `then` block if the deferred is subsequently resolved", ^{
                [deferred resolveWithValue:@123];
                thenBlockCalledWithValue should be_nil;
            });

            it(@"should not fire the promise's `error` block if the deferred is subsequently rejected", ^{
                NSError *rejectError = [NSError errorWithDomain:@"asdf" code:123 userInfo:nil];
                [deferred rejectWithError:rejectError];
                errorBlockCalledWithError should be_nil;
            });
        });

        context(@"for a child promise", ^{
            beforeEach(^{
                [childPromise cancel];
            });

            it(@"should call the cancel block of the deferred", ^{
                cancelBlockCalled should be_truthy;
            });

            it(@"should not fire the parent promise's `then` block if the deferred is subsequently resolved", ^{
                [deferred resolveWithValue:@123];
                thenBlockCalledWithValue should be_nil;
            });

            it(@"should not fire the parent promise's `error` block if the deferred is subsequently rejected", ^{
                NSError *rejectError = [NSError errorWithDomain:@"asdf" code:123 userInfo:nil];
                [deferred rejectWithError:rejectError];
                errorBlockCalledWithError should be_nil;
            });
        });

        context(@"for a joined promise", ^{
            __block KSDeferred *otherDeferred;
            __block KSPromise *joinedPromise;
            __block BOOL otherDeferredCancelBlockCalled;
            beforeEach(^{
                otherDeferredCancelBlockCalled = NO;
                otherDeferred = [KSDeferred defer];
                [otherDeferred whenCancelled: ^{
                    otherDeferredCancelBlockCalled = YES;
                }];

                KSPromise *otherPromise = otherDeferred.promise;
                joinedPromise = [KSPromise join:@[childPromise, otherPromise]];
                [joinedPromise cancel];
            });

            it(@"should call the cancel block of both deferreds", ^{
                cancelBlockCalled should be_truthy;
                otherDeferredCancelBlockCalled should be_truthy;
            });
        });
    });
});

SPEC_END
