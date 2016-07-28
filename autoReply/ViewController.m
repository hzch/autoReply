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
@property (nonatomic) NSArray *replyStrings;
@property (weak, nonatomic) IBOutlet UIView *lockView;

@property (nonatomic) BOOL isVerifyCode;

@end

@implementation ViewController
- (IBAction)lock:(id)sender {
    self.lockView.hidden = !self.lockView.hidden;
}

- (NSString*)randomString
{
    NSArray *replys = [self replyStrings];
    return replys[(arc4random() % replys.count)];
}

- (NSArray*)replyStrings
{
    if (_replyStrings) {
        return _replyStrings;
    }
    NSMutableArray *arr = [@[] mutableCopy];
    NSArray *f1 = @[@"wo", @"我", @"ni", @"你", @""];
    NSArray *f2 = @[@"zai", @"再", @"在", @""];
    NSArray *f3 = @[@"ding", @"顶", @"丁",@""];
    NSArray *f4 = @[@"ding", @"顶", @"丁"];
    NSArray *f5 = @[@".", @",", @"!", @"，", @"。", @"！", @""];
    for (int i = 0; i != f1.count; i++) {
        for (int j = 0; j != f2.count; j++) {
            for (int k = 0; k != f3.count; k++) {
                for (int l = 0; l != f4.count; l++) {
                    for (int m = 0; m != f5.count; m++) {
                        [arr addObject:[NSString stringWithFormat:@"%@%@%@%@%@", f1[i], f2[j], f3[k], f4[l], f5[m]]];
                    }
                }
            }
        }
    }
    _replyStrings = arr;
    return arr;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    [self readLogInFile];
    NSString *urlStr = [[NSUserDefaults standardUserDefaults] objectForKey:@"gotoReply"];
    if (urlStr.length != 0) {
        [self.webview loadRequest:[NSURLRequest requestWithURL:[NSURL URLWithString:urlStr]]];
    } else {
        [self.webview loadRequest:[NSURLRequest requestWithURL:[NSURL URLWithString:@"http://tieba.baidu.com"]]];
    }
}

- (BOOL)webView:(UIWebView *)webView shouldStartLoadWithRequest:(NSURLRequest *)request navigationType:(UIWebViewNavigationType)navigationType
{
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
            [self log:request.URL.absoluteString];
            [self autoReply];
        } else {
            [self log:@"auto submit"];
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
        min = 4;
    } else if (hour == 0 || hour == 7) {
        min = 10;
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

@end
