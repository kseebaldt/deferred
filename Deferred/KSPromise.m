#import "KSPromise.h"
#import <TargetConditionals.h>

#if TARGET_OS_IPHONE
#   if __IPHONE_OS_VERSION_MIN_REQUIRED < 60000
#       define KS_DISPATCH_RELEASE(q) (dispatch_release(q))
#   endif
#else
#   if MAC_OS_X_VERSION_MIN_REQUIRED < 1080
#       define KS_DISPATCH_RELEASE(q) (dispatch_release(q))
#   endif
#endif
#ifndef KS_DISPATCH_RELEASE
#   define KS_DISPATCH_RELEASE(q)
#endif

@interface KSPromiseCallbacks : NSObject
@property (copy, nonatomic) promiseValueCallback fulfilledCallback;
@property (copy, nonatomic) promiseErrorCallback errorCallback;

@property (copy, nonatomic) deferredCallback deprecatedFulfilledCallback;
@property (copy, nonatomic) deferredCallback deprecatedErrorCallback;
@property (copy, nonatomic) deferredCallback deprecatedCompleteCallback;

@property (strong, nonatomic) KSPromise *childPromise;
@end

@implementation KSPromiseCallbacks

- (id)initWithFulfilledCallback:(promiseValueCallback)fulfilledCallback errorCallback:(promiseErrorCallback)errorCallback {
    self = [super init];
    if (self) {
        self.fulfilledCallback = fulfilledCallback;
        self.errorCallback = errorCallback;
        self.childPromise = [[KSPromise alloc] init];
    }
    return self;
}

@end

@interface KSPromise () {
    dispatch_semaphore_t _sem;
}

@property (strong, nonatomic) NSMutableArray *callbacks;
@property (strong, nonatomic) NSMutableArray *parentPromises;

@property (strong, nonatomic, readwrite) id value;
@property (strong, nonatomic, readwrite) NSError *error;

@property (assign, nonatomic) BOOL fulfilled;
@property (assign, nonatomic) BOOL rejected;
@property (assign, nonatomic) BOOL cancelled;

@end

@implementation KSPromise

- (id)init {
    self = [super init];
    if (self) {
        self.callbacks = [NSMutableArray array];
        _sem = dispatch_semaphore_create(0);
    }
    return self;
}

- (void)dealloc {
    KS_DISPATCH_RELEASE(_sem);
}

+ (KSPromise *)when:(NSArray *)promises {
    KSPromise *promise = [[KSPromise alloc] init];
    promise.parentPromises = [NSMutableArray array];
    [promise.parentPromises addObjectsFromArray:promises];
    for (KSPromise *joinedPromise in promises) {
        [joinedPromise then:^id(id value) {
            [promise joinedPromiseFulfilled:joinedPromise];
            return value;
        } error:^id(NSError *error) {
            [promise joinedPromiseFulfilled:joinedPromise];
            return error;
        }];
    }
    return promise;
}

+ (KSPromise *)join:(NSArray *)promises {
    return [self when:promises];
}

- (KSPromise *)then:(promiseValueCallback)fulfilledCallback
              error:(promiseErrorCallback)errorCallback {
    if (self.cancelled) return nil;
    if (![self completed]) {
        KSPromiseCallbacks *callbacks = [[KSPromiseCallbacks alloc] initWithFulfilledCallback:fulfilledCallback
                                                                                errorCallback:errorCallback];
        [self.callbacks addObject:callbacks];
        return callbacks.childPromise;
    }

    id nextValue;
    if (self.fulfilled) {
        nextValue = self.value;
        if (fulfilledCallback) {
           nextValue = fulfilledCallback(self.value);
        }
    } else if (self.rejected) {
        nextValue = self.error;
        if (errorCallback) {
            nextValue = errorCallback(self.error);
        }
    }
    KSPromise *promise = [[KSPromise alloc] init];
    [self resolvePromise:promise withValue:nextValue];
    return promise;
}

- (void)cancel {
    self.cancelled = YES;
    [self.callbacks removeAllObjects];
}

- (id)waitForValue {
    return [self waitForValueWithTimeout:0];
}

- (id)waitForValueWithTimeout:(NSTimeInterval)timeout {
    if (![self completed]) {
        dispatch_time_t time = timeout == 0 ? DISPATCH_TIME_FOREVER : dispatch_time(DISPATCH_TIME_NOW, timeout * NSEC_PER_SEC);
        dispatch_semaphore_wait(_sem, time);
    }
    if (self.fulfilled) {
        return self.value;
    } else if (self.rejected) {
        return self.error;
    }
    return [NSError errorWithDomain:@"KSPromise" code:1 userInfo:@{NSLocalizedDescriptionKey: @"Timeout exceeded while waiting for value"}];
}

#pragma mark - Resolving and Rejecting

- (void)resolveWithValue:(id)value {
    if (self.completed || self.cancelled) return;
    self.value = value;
    self.fulfilled = YES;
    for (KSPromiseCallbacks *callbacks in self.callbacks) {
        id nextValue = self.value;
        if (callbacks.fulfilledCallback) {
            nextValue = callbacks.fulfilledCallback(value);
        } else if (callbacks.deprecatedFulfilledCallback) {
            callbacks.deprecatedFulfilledCallback(self);
            continue;
        }
        [self resolvePromise:callbacks.childPromise withValue:nextValue];
    }
    [self finish];
}

- (void)rejectWithError:(NSError *)error {
    if (self.completed || self.cancelled) return;
    self.error = error;
    self.rejected = YES;
    for (KSPromiseCallbacks *callbacks in self.callbacks) {
        id nextValue = self.error;
        if (callbacks.errorCallback) {
            nextValue = callbacks.errorCallback(error);
        } else if (callbacks.deprecatedErrorCallback) {
            callbacks.deprecatedErrorCallback(self);
            continue;
        }
        [self resolvePromise:callbacks.childPromise withValue:nextValue];
    }
    [self finish];
}

- (void)resolvePromise:(KSPromise *)promise withValue:(id)value {
    if ([value isKindOfClass:[NSError class]]) {
        [promise rejectWithError:value];
    } else {
        [promise resolveWithValue:value];
    }
}

- (void)finish {
    for (KSPromiseCallbacks *callbacks in self.callbacks) {
        if (callbacks.deprecatedCompleteCallback) {
            callbacks.deprecatedCompleteCallback(self);
        }
    }
    [self.callbacks removeAllObjects];
    dispatch_semaphore_signal(_sem);
}

- (BOOL)completed {
    return self.fulfilled || self.rejected;
}

#pragma mark - Deprecated methods
- (void)whenResolved:(deferredCallback)callback {
    if (self.fulfilled) {
        callback(self);
    } else if (!self.cancelled) {
        KSPromiseCallbacks *callbacks = [[KSPromiseCallbacks alloc] init];
        callbacks.deprecatedFulfilledCallback = callback;
        [self.callbacks addObject:callbacks];
    }
}

- (void)whenRejected:(deferredCallback)callback {
    if (self.rejected) {
        callback(self);
    } else if (!self.cancelled) {
        KSPromiseCallbacks *callbacks = [[KSPromiseCallbacks alloc] init];
        callbacks.deprecatedErrorCallback = callback;
        [self.callbacks addObject:callbacks];
    }
}

- (void)whenFulfilled:(deferredCallback)callback {
    if ([self completed]) {
        callback(self);
    } else if (!self.cancelled) {
        KSPromiseCallbacks *callbacks = [[KSPromiseCallbacks alloc] init];
        callbacks.deprecatedCompleteCallback = callback;
        [self.callbacks addObject:callbacks];
    }
}

#pragma mark - Private methods
- (void)joinedPromiseFulfilled:(KSPromise *)promise {
    BOOL fulfilled = YES;
    NSMutableArray *errors = [NSMutableArray array];
    NSMutableArray *values = [NSMutableArray array];
    for (KSPromise *joinedPromise in self.parentPromises) {
        fulfilled = fulfilled && joinedPromise.completed;
        if (joinedPromise.rejected) {
            [errors addObject:joinedPromise.error];
        } else if (joinedPromise.fulfilled) {
            [values addObject:joinedPromise.value];
        }
    }
    if (fulfilled) {
        if (errors.count > 0) {
            [self rejectWithError:[NSError errorWithDomain:@"KSPromiseJoinError" code:1 userInfo:[NSDictionary dictionaryWithObject:errors forKey:@"errors"]]];
        } else {
            [self resolveWithValue:values];
        }
    }
}

@end
