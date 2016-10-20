//
//  ViewController.m
//  autoReply
//
//  Created by Jiang on 16/6/6.
//  Copyright © 2016年 hzch. All rights reserved.
//

#import "ViewController.h"

@interface NSDate (String)
@end
@implementation NSDate (String)
+ (NSString *)currentString
{
    NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
    [dateFormatter setDateFormat:@"yyyy-MM-dd HH:mm:ss"];
    return [dateFormatter stringFromDate:[NSDate date]];
}

+ (NSString *)dateAfterSeconds:(NSInteger)seconds
{
    NSDate *date = [NSDate dateWithTimeIntervalSinceNow:seconds];
    NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
    [dateFormatter setDateFormat:@"HH:mm:ss"];
    return [dateFormatter stringFromDate:date];
}


+ (NSInteger)hour
{
    NSCalendar* calendar = [NSCalendar currentCalendar];
    NSDateComponents* components = [calendar components:NSCalendarUnitHour fromDate:[NSDate date]];
    return [components hour];
}
@end

@interface ViewController () <UIWebViewDelegate>
@property (weak, nonatomic) IBOutlet UIWebView *webview;
@property (weak, nonatomic) IBOutlet UITextView *logTextView;
@property (nonatomic) NSURLRequest *replyRequest;
@property (weak, nonatomic) IBOutlet UIView *lockView;
@property (nonatomic) NSString *currentRequestString;
@property (nonatomic) BOOL isVerifyCode;

@end

@implementation ViewController
- (IBAction)lock:(id)sender {
    self.lockView.hidden = !self.lockView.hidden;
}

- (NSString*)randomString
{
    return @"啊噗";
}

- (void)viewDidLoad {
    [super viewDidLoad];
    [self readLogInFile];
    NSString *urlStr = [[NSUserDefaults standardUserDefaults] objectForKey:@"gotoReply"];
    if (urlStr.length != 0) {
        [self.webview loadRequest:[NSURLRequest requestWithURL:[NSURL URLWithString:urlStr]]];
    } else {
        [self.webview loadRequest:[NSURLRequest requestWithURL:[NSURL URLWithString:@"https://tieba.baidu.com"]]];
    }
}

- (BOOL)webView:(UIWebView *)webView shouldStartLoadWithRequest:(NSURLRequest *)request navigationType:(UIWebViewNavigationType)navigationType
{
    self.currentRequestString = request.URL.absoluteString;
    NSMutableURLRequest *mutableRequest = (NSMutableURLRequest*)request;
    if (request.HTTPBody.length != 0) {
        NSString *form = [[NSString alloc] initWithData:request.HTTPBody encoding:NSUTF8StringEncoding];
        if ([form hasPrefix:@"co="]) {
            NSString *coString = [form componentsSeparatedByString:@"&"].firstObject;
            NSString *newForm = [NSString stringWithFormat:@"co=%@%@", [self randomString], [form substringFromIndex:coString.length]];
            [mutableRequest setHTTPBody:[newForm dataUsingEncoding:NSUTF8StringEncoding]];
            request = mutableRequest;
        }
    }
    BOOL isGotoReply = [request.URL.absoluteString rangeOfString:@"&pn=0"].length != 0;
    if (isGotoReply) {
        [[NSUserDefaults standardUserDefaults] setObject:request.URL.absoluteString forKey:@"gotoReply"];
    }
    BOOL isSubmit = [request.URL.absoluteString hasSuffix:@"/submit"];
    if (isSubmit) {
        if (!self.replyRequest || ![self.replyRequest.URL.absoluteString isEqualToString:request.URL.absoluteString]) {
            [self autoReply];
        }
        self.replyRequest = request;
    }
    return YES;
}

-(void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    [self log:@"didReceiveMemoryWarning"];
    [[NSURLCache sharedURLCache] removeAllCachedResponses];
}

- (void)webViewDidFinishLoad:(UIWebView *)webView
{
    [[NSUserDefaults standardUserDefaults] setInteger:0 forKey:@"WebKitCacheModelPreferenceKey"];
    NSString *title = [self.webview stringByEvaluatingJavaScriptFromString:@"document.getElementsByTagName('title')[0].innerHTML"];
    self.isVerifyCode = title != nil && [title rangeOfString:@"输入验证码"].length != 0;
}

- (void)autoReply
{
    if (self.isVerifyCode) {
        __weak typeof(self) weakSelf = self;
        [self log:@"Next at %@.", [NSDate dateAfterSeconds:3700]];
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(3700 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
            if (weakSelf.replyRequest) {
                [weakSelf.webview loadRequest:weakSelf.replyRequest];
                [weakSelf autoReply];
            }
        });
        return;
    }
    NSInteger min;
    NSInteger hour = [NSDate hour];
    
    if (hour > 7) {
        min = 10;
    } else if (hour == 0 || hour == 7) {
        min = 30;
    } else {
        min = 60;
    }
    
    NSInteger seconds = 60 * ((arc4random() % 3) + min) + (arc4random() % 60);
    
    ;
    [self log:@"Next at %@.", [NSDate dateAfterSeconds:seconds]];
    __weak typeof(self) weakSelf = self;
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(seconds * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        if (weakSelf.replyRequest) {
            [weakSelf.webview loadRequest:weakSelf.replyRequest];
            [weakSelf autoReply];
        }
    });
}

- (void)writeLogToFile
{
    [self.logTextView.text writeToFile:[self.class logFilePath]
                            atomically:YES
                              encoding:NSUTF8StringEncoding
                                 error:nil];
}

- (void)readLogInFile
{
    if ([[NSFileManager defaultManager] fileExistsAtPath:[self.class logFilePath]]) {
        self.logTextView.text = [NSString stringWithContentsOfFile:[self.class logFilePath]
                                                          encoding:NSUTF8StringEncoding
                                                             error:nil];
    }
    
    [self log:@"App started."];
}

- (void)log:(NSString *)content, ...
{
    va_list vl;
    va_start(vl, content);
    NSString* allContent = [[NSString alloc] initWithFormat:content arguments:vl];
    va_end(vl);
    allContent = [NSString stringWithFormat:@"[[[%@]]] %@\n", [NSDate currentString], allContent];
    if (self.logTextView.text.length > 1000) {
        self.logTextView.text = [self.logTextView.text substringToIndex:1000];
    }
    self.logTextView.text = [allContent stringByAppendingString:self.logTextView.text];
    [self writeLogToFile];
}

+ (NSString *)logFilePath {
    return [[self documentsPath] stringByAppendingPathComponent:@"log.txt"];
}

+ (NSString *)documentsPath {
    return NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES)[0];
}

#pragma mark - action
- (IBAction)back:(id)sender {
    [self.webview goBack];
}
- (IBAction)refresh:(id)sender {
    [self.webview reload];
}
- (IBAction)pre:(id)sender {
    [self.webview goForward];
}
- (IBAction)save:(id)sender {
    [[NSUserDefaults standardUserDefaults] setObject:self.currentRequestString forKey:@"saveUrl"];
}
- (IBAction)goSave:(id)sender {
    NSString *urlStr = [[NSUserDefaults standardUserDefaults] objectForKey:@"saveUrl"];
    if (urlStr.length != 0) {
        [self.webview loadRequest:[NSURLRequest requestWithURL:[NSURL URLWithString:urlStr]]];
    } else {
        [self.webview loadRequest:[NSURLRequest requestWithURL:[NSURL URLWithString:@"https://tieba.baidu.com"]]];
    }
}


@end
