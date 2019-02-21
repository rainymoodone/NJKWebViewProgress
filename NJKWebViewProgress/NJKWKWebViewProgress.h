//
//  NJKWKWebViewProgress.h
//
//  Created by Satoshi Aasano on 4/20/13.
//  Copyright (c) 2013 Satoshi Asano. All rights reserved.
//

#import <Foundation/Foundation.h>

#undef njk_weak
#if __has_feature(objc_arc_weak)
#define njk_weak weak
#else
#define njk_weak unsafe_unretained
#endif

#import <WebKit/WebKit.h>

typedef void (^NJKWKWebViewProgressBlock)(float progress);
@protocol NJKWKWebViewProgressDelegate;
@interface NJKWKWebViewProgress : NSObject<WKNavigationDelegate>
@property (nonatomic, njk_weak) id<NJKWKWebViewProgressDelegate>progressDelegate;
@property (nonatomic, copy) NJKWKWebViewProgressBlock progressBlock;
@property (nonatomic, readonly) float progress; // 0.0..1.0

- (void)reset;
@end

@protocol NJKWKWebViewProgressDelegate <NSObject>
- (void)webViewProgress:(NJKWKWebViewProgress *)webViewProgress updateProgress:(float)progress;
@end

