#import "KSPromise.h"

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

@interface KSPromise ()
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
    }
    return self;
}

+ (KSPromise *)join:(NSArray *)promises {
    KSPromise *promise = [[KSPromise alloc] init];
    promise.parentPromises = [NSMutableArray array];
    for (KSPromise *joinedPromise in promises) {
        [promise.parentPromises addObject:joinedPromise];
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

- (KSPromise *)then:(promiseValueCallback)fulfilledCallback error:(promiseErrorCallback)errorCallback {
    if (self.cancelled) return nil;
    if (self.fulfilled) {
        id newValue = self.value;
        if (fulfilledCallback) {
           newValue = fulfilledCallback(self.value);
        }
        KSPromise *promise = [[KSPromise alloc] init];
        if ([newValue isKindOfClass:[NSError class]]) {
            [promise rejectWithError:newValue];
        } else {
            [promise resolveWithValue:newValue];
        }
        return promise;
    } else if (self.rejected) {
        id nextValue = self.error;
        if (errorCallback) {
            nextValue = errorCallback(self.error);
        }
        KSPromise *promise = [[KSPromise alloc] init];
        if ([nextValue isKindOfClass:[NSError class]]) {
            [promise rejectWithError:nextValue];
        } else {
            [promise resolveWithValue:nextValue];
        }
        return promise;
    }
    KSPromiseCallbacks *callbacks = [[KSPromiseCallbacks alloc] initWithFulfilledCallback:fulfilledCallback errorCallback:errorCallback];
    [self.callbacks addObject:callbacks];
    return callbacks.childPromise;
}

- (void)cancel {
    self.cancelled = YES;
    [self.callbacks removeAllObjects];
}

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
        if ([nextValue isKindOfClass:[NSError class]]) {
            [callbacks.childPromise rejectWithError:nextValue];
        } else {
            [callbacks.childPromise resolveWithValue:nextValue];
        }
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
            nextValue= callbacks.errorCallback(error);
        } else if (callbacks.deprecatedErrorCallback) {
            callbacks.deprecatedErrorCallback(self);
            continue;
        }
        if ([nextValue isKindOfClass:[NSError class]]) {
            [callbacks.childPromise rejectWithError:nextValue];
        } else {
            [callbacks.childPromise resolveWithValue:nextValue];
        }
    }
    [self finish];
}

- (void)finish {
    for (KSPromiseCallbacks *callbacks in self.callbacks) {
        if (callbacks.deprecatedCompleteCallback) {
            callbacks.deprecatedCompleteCallback(self);
        }
    }
    [self.callbacks removeAllObjects];
}

- (BOOL)completed {
    return self.fulfilled || self.rejected;
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
