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

@property (nonatomic) BOOL isVerifyCode;

@end

@implementation ViewController

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
    NSMutableArray *arr = [@[@"生意兴隆通四海，财源茂盛达三江、马到功成",
             @"大展宏图，宝地生金，恭喜发财，四通八达",
             @"五湖四海、六六大顺、七平八稳、八面玲珑",
             @"九十春光、十全十美、百发百中、千姿百态、万紫千红",
             @"秋高气爽，时光鎏金。祝愿客户多多，钞票满满啊。",
             @"幽香拂面，紫气兆祥，祝生意如春浓，财源似水来！",
             @"一艘刚刚起航的航船，让我们一起向往建设更美好的明天。",
             @"愿生意早日盈利，盈利多多啊。多多啊多多。",
             @"开拓事业的犁铧，尽管如此沉重,但您以非凡的毅力，毕竟一步一步地走过来了。",
             @"愿我们的掌声，化作潇潇春雨，助您播下美好未来的良种！",
             @"热情的面容,千姿百态、万紫千红。",
             @"前天祝贺早了点，今天祝贺挤了点，明天祝贺迟了点，现在祝贺是正点。",
             @"祝愿生意财源滚滚，如日中天，兴旺发达，开张大吉啊！",
             @"明察秋毫，日月重光。锐眼观天下，妙笔写春秋。",
             @"成功的花，人们只惊羡她现时的鲜艳，然而往往忽略了当初她的芽儿曾浸透了奋斗的泪泉。",
             @"我赞赏您的成功，更钦佩您在艰难的小道上曲折前行的精神。",
             @"明察秋毫，日月重光。锐眼观天下，妙笔写春秋。生意兴隆通四海。",
             @"人民生活水平不断提高，广大群众的物质文化生活需要越来越高",
             @"希望你就是这个能不断满足大家需求的人，生意兴隆发财啊。",
             @"根深叶茂无疆业，源远流长有道财。",
             @"东风利市春来有象，生意兴隆日进无疆。",
             @"送上诚挚祝贺，情深意重，事业蒸蒸日上，财源广进！",
             @"生意财源滚滚，如日中天，兴旺发达，开张大吉啊！",
             @"火红的事业财源广进，温馨的祝愿繁荣昌隆，美好的祝福送上来！",
                            @"高山上的人总比平原上的人先看到日出。高瞻远瞩，前景辉煌。鹏程万里!"] mutableCopy];
    NSArray *chengyu = @[@"锦绣前程",
             @"鹏程万里",
             @"事事顺利",
             @"合家欢乐",
             @"春风得意",
             @"前程似锦",
             @"大展鹏图",
             @"生意兴隆",
             @"马到功成",
             @"工作顺利",
             @"事业有成",
             @"天天开心",
             @"快乐永远",
             @"身体健康",
             @"万事如意",
             @"福如东海",
             @"心想事成",
             @"大吉大利",
             @"招财进宝",
             @"一帆风顺",
             @"福寿双全",
             @"三羊开泰",
             @"四季发财",
             @"五福临门",
             @"六六大顺",
             @"财源滚滚",
             @"日升月恒",
             @"万事亨通",
             @"蒸蒸日上",
             @"财源广进",
             @"金玉满堂"];
    NSArray *dot = @[@"",@" ",@"  ",@",",@".",@"!",@";",@"，",@"。",@"！",@"；"];
    for (int i = 0; i != chengyu.count - 3; i ++) {
        for (int j = i + 1; j != chengyu.count - 2; j ++) {
            for (int k = j + 1; k != chengyu.count - 1; k ++) {
                for (int l = k + 1; l != chengyu.count; l ++) {
                    [arr addObject:[NSString stringWithFormat:@"%@%@%@%@%@%@%@%@", chengyu[i], dot[arc4random() % dot.count], chengyu[j], dot[arc4random() % dot.count], chengyu[k], dot[arc4random() % dot.count], chengyu[l], dot[arc4random() % dot.count]]];
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

- (void)webViewDidFinishLoad:(UIWebView *)webView
{
    NSString *title = [self.webview stringByEvaluatingJavaScriptFromString:@"document.getElementsByTagName('title')[0].innerHTML"];
    self.isVerifyCode = title != nil && [title rangeOfString:@"输入验证码"].length != 0;
}
- (void)webView:(UIWebView *)webView didFailLoadWithError:(nullable NSError *)error
{
    [self.webview loadRequest:[NSURLRequest requestWithURL:[NSURL URLWithString:@"http://tieba.baidu.com"]]];
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
