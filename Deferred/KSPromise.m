#import "KSDeferred.h"

@interface KSPromise ()
@property (strong, nonatomic, readwrite) NSMutableArray *parentPromises;

@property (strong, nonatomic) NSMutableArray *fulfilledCallbacks;
@property (strong, nonatomic) NSMutableArray *resolvedCallbacks;
@property (strong, nonatomic) NSMutableArray *rejectedCallbacks;

@property (nonatomic, getter=isResolved) BOOL resolved;
@property (nonatomic, getter=isRejected) BOOL rejected;
@property (nonatomic) BOOL cancelled;
@end

@implementation KSPromise

@synthesize parentPromises = _parentPromises;
@synthesize fulfilledCallbacks = _fulfilledCallbacks, resolvedCallbacks = _resolvedCallbacks, rejectedCallbacks = _rejectedCallbacks;
@synthesize value = _value, error = _error;
@synthesize resolved = _resolved, rejected = _rejected;
@synthesize cancelled = _cancelled;

- (id)init {
    self = [super init];
    if (self) {
        self.parentPromises = [NSMutableArray array];
        self.fulfilledCallbacks = [NSMutableArray array];
        self.resolvedCallbacks = [NSMutableArray array];
        self.rejectedCallbacks = [NSMutableArray array];
    }
    return self;
}

+ (KSPromise *)join:(NSArray *)promises {
    KSPromise *promise = [[KSPromise alloc] init];
    for (KSPromise *joinedPromise in promises) {
        [promise.parentPromises addObject:joinedPromise];
        [joinedPromise whenFulfilled:^(KSPromise *fulfilledPromise) {
           [promise joinedPromiseFulfilled:fulfilledPromise];
        }];
    }
    return promise;
}

- (BOOL)isFulfilled {
    return self.isResolved || self.isRejected;
}

- (KSPromise *)whenFulfilled:(deferredCallback)callback {
    if (self.isFulfilled) {
        callback(self);
    } else if (!self.cancelled) {
        [self.fulfilledCallbacks addObject:[callback copy]];
    }
    return self;
}

- (KSPromise *)whenResolved:(deferredCallback)callback {
    if (self.isResolved) {
        callback(self);
    } else if (!self.cancelled) {
        [self.resolvedCallbacks addObject:[callback copy]];
    }
    return self;
}

- (KSPromise *)whenRejected:(deferredCallback)callback {
    if (self.isRejected) {
        callback(self);
    } else if (!self.cancelled) {
        [self.rejectedCallbacks addObject:[callback copy]];
    }    
    return self;
}

- (void)resolveWithValue:(id)value {
    self.value = value;
    self.resolved = YES;
    if (self.cancelled) return;
    for (deferredCallback callback in self.resolvedCallbacks) {
        callback(self);
    }
    [self fulfill];
}

- (void)rejectWithError:(NSError *)error {
    self.error = error;
    self.rejected = YES;
    if (self.cancelled) return;
    for (deferredCallback callback in self.rejectedCallbacks) {
        callback(self);
    }
    [self fulfill];
}

- (void)fulfill {
    for (deferredCallback callback in self.fulfilledCallbacks) {
        callback(self);
    }
    [self.resolvedCallbacks removeAllObjects];
    [self.rejectedCallbacks removeAllObjects];
    [self.fulfilledCallbacks removeAllObjects];
}

- (void)cancel {
    self.cancelled = YES;
    [self.resolvedCallbacks removeAllObjects];
    [self.rejectedCallbacks removeAllObjects];
    [self.fulfilledCallbacks removeAllObjects];
}

- (NSArray *)joinedPromises {
    return self.parentPromises;
}

#pragma mark - Private methods
- (void)joinedPromiseFulfilled:(KSPromise *)promise {
    BOOL fulfilled = YES;
    NSMutableArray *errors = [NSMutableArray array];
    NSMutableArray *values = [NSMutableArray array];
    for (KSPromise *joinedPromise in self.parentPromises) {
        fulfilled = fulfilled && joinedPromise.isFulfilled;
        if (joinedPromise.isRejected) {
            [errors addObject:joinedPromise.error];
        } else if (joinedPromise.isResolved) {
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
