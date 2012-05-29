Async library inspired by CommonJS/jQuery deferreds

# Example

## Getting a promise from a NSURLConnection

    NSURLRequest *request = [NSURLRequest requestWithURL:[NSURL URLWithString:@"http://www.example.com/test"]];
    KSPromise *promise = [NSURLConnection sendRequest:request];

## Adding callback to the promise

        [promise whenResolved:^(KSPromise *p) {
            // look at the value
            p.value; 
        }];
        [promise whenRejected:^(KSPromise *p) {
            // look at the error
            p.error; 
        }];

## Joining on multiple promises

    KSPromise *promise = [KSPromise join:[NSArray arrayWithObjects:promise1, promise2, nil]];

    [promise whenResolved:^(KSPromise *p) {
        // will only be called after all joined promises are resolved
    }];
