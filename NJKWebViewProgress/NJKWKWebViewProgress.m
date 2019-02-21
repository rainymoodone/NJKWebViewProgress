//
//  NJKWKWebViewProgress.m
//
//  Created by Satoshi Aasano on 4/20/13.
//  Copyright (c) 2013 Satoshi Asano. All rights reserved.
//

#import "NJKWKWebViewProgress.h"

NSString *NJKWKCompleteRPCURL = @"webviewprogressproxy:///complete";

const float NJKWKInitialProgressValue = 0.1f;
const float NJKWKInteractiveProgressValue = 0.5f;
const float NJKWKFinalProgressValue = 0.9f;

@implementation NJKWKWebViewProgress
{
    NSUInteger _loadingCount;
    NSUInteger _maxLoadCount;
    NSURL *_currentURL;
    BOOL _interactive;
}

- (id)init
{
    self = [super init];
    if (self) {
        _maxLoadCount = _loadingCount = 0;
        _interactive = NO;
    }
    return self;
}

- (void)startProgress
{
    if (_progress < NJKWKInitialProgressValue) {
        [self setProgress:NJKWKInitialProgressValue];
    }
}

- (void)incrementProgress
{
    float progress = self.progress;
    float maxProgress = _interactive ? NJKWKFinalProgressValue : NJKWKInteractiveProgressValue;
    float remainPercent = (float)_loadingCount / (float)_maxLoadCount;
    float increment = (maxProgress - progress) * remainPercent;
    progress += increment;
    progress = fmin(progress, maxProgress);
    [self setProgress:progress];
}

- (void)completeProgress
{
    [self setProgress:1.0];
}

- (void)setProgress:(float)progress
{
    // progress should be incremental only
    if (progress > _progress || progress == 0) {
        _progress = progress;
        if ([_progressDelegate respondsToSelector:@selector(webViewProgress:updateProgress:)]) {
            [_progressDelegate webViewProgress:self updateProgress:progress];
        }
        if (_progressBlock) {
            _progressBlock(progress);
        }
    }
}

- (void)reset
{
    _maxLoadCount = _loadingCount = 0;
    _interactive = NO;
    [self setProgress:0.0];
}

#pragma mark -
#pragma mark UIWebViewDelegate

- (void)webView:(WKWebView *)webView decidePolicyForNavigationAction:(WKNavigationAction *)navigationAction decisionHandler:(void (^)(WKNavigationActionPolicy))decisionHandler {
    
    NSURLRequest *request = navigationAction.request;
    if ([request.URL.absoluteString isEqualToString:NJKWKCompleteRPCURL]) {
        [self completeProgress];
    }
    
    BOOL ret = YES;
    BOOL isFragmentJump = NO;
    if (request.URL.fragment) {
        NSString *nonFragmentURL = [request.URL.absoluteString stringByReplacingOccurrencesOfString:[@"#" stringByAppendingString:request.URL.fragment] withString:@""];
        isFragmentJump = [nonFragmentURL isEqualToString:request.URL.absoluteString];
    }
    
    BOOL isTopLevelNavigation = [request.mainDocumentURL isEqual:request.URL];
    
    BOOL isHTTP = [request.URL.scheme isEqualToString:@"http"] || [request.URL.scheme isEqualToString:@"https"];
    if (ret && !isFragmentJump && isHTTP && isTopLevelNavigation) {
        _currentURL = request.URL;
        [self reset];
    }
}


- (void)webView:(WKWebView *)webView didStartProvisionalNavigation:(null_unspecified WKNavigation *)navigation {
    _loadingCount++;
    _maxLoadCount = fmax(_maxLoadCount, _loadingCount);
    
    [self startProgress];
}

- (void)webView:(WKWebView *)webView didFinishNavigation:(null_unspecified WKNavigation *)navigation {
    
    _loadingCount--;
    [webView evaluateJavaScript:@"document.readyState" completionHandler:^(id _Nullable result, NSError * _Nullable error) {
        NSString *readyState = @"";
        if ([result isKindOfClass:[NSString class]]) {
            readyState = (NSString *)result;
        }
        BOOL interactive = [readyState isEqualToString:@"interactive"];
        if (interactive) {
            _interactive = YES;
            NSString *waitForCompleteJS = [NSString stringWithFormat:@"window.addEventListener('load',function() { var iframe = document.createElement('iframe'); iframe.style.display = 'none'; iframe.src = '%@'; document.body.appendChild(iframe);  }, false);", NJKWKCompleteRPCURL];
            [webView evaluateJavaScript:waitForCompleteJS completionHandler:nil];
        }
        [self incrementProgress];
        
        BOOL isNotRedirect = _currentURL && [_currentURL isEqual:webView.URL];
        BOOL complete = [readyState isEqualToString:@"complete"];
        
        if (complete && isNotRedirect) {
            [self completeProgress];
        }
    }];
}

- (void)webView:(WKWebView *)webView didFailNavigation:(null_unspecified WKNavigation *)navigation withError:(NSError *)error {
    _loadingCount--;
    
    [webView evaluateJavaScript:@"document.readyState" completionHandler:^(id _Nullable result, NSError * _Nullable error) {
        NSString *readyState = @"";
        if ([result isKindOfClass:[NSString class]]) {
            readyState = (NSString *)result;
        }
        
        BOOL interactive = [readyState isEqualToString:@"interactive"];
        if (interactive) {
            _interactive = YES;
            NSString *waitForCompleteJS = [NSString stringWithFormat:@"window.addEventListener('load',function() { var iframe = document.createElement('iframe'); iframe.style.display = 'none'; iframe.src = '%@'; document.body.appendChild(iframe);  }, false);", NJKWKCompleteRPCURL];
            [webView evaluateJavaScript:waitForCompleteJS completionHandler:nil];
        }
        [self incrementProgress];
        
        BOOL isNotRedirect = _currentURL && [_currentURL isEqual:webView.URL];
        BOOL complete = [readyState isEqualToString:@"complete"];
        if (complete && isNotRedirect) {
            [self completeProgress];
        }
    }];
}

@end
