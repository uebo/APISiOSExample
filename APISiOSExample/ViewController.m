//
//  ViewController.m
//  APISiOSExample
//
//  Created by 植田 洋次 on 2014/09/10.
//  Copyright (c) 2014年 Yoji Ueda. All rights reserved.
//

#import "ViewController.h"

/**
 *  cell identifier
 */
static NSString *const kCellIdentifier = @"cell";

@interface ViewController ()

/**
 *  Datastoreからのobjectを格納する配列
 */
@property (strong, nonatomic) NSMutableArray *collections;

@property (strong, nonatomic) UIRefreshControl *refreshControl;

-(IBAction)addButtonAction:(id)sender;

@end
@implementation ViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    //配列を初期化
    self.collections = [[NSMutableArray alloc] init];
    
    //RefreshControl
    self.refreshControl = [[UIRefreshControl alloc] init];
    [self.refreshControl addTarget:self
                            action:@selector(refreshAction:)
                  forControlEvents:UIControlEventValueChanged];
    [self.tableView addSubview:self.refreshControl];
    
    [self refreshAction:nil];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

#pragma mark - UITableViewDataSource

-(NSInteger)tableView:(UITableView *)tableView
numberOfRowsInSection:(NSInteger)section
{
    return [self.collections count];
}

-(UITableViewCell *)tableView:(UITableView *)tableView
        cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:kCellIdentifier];
    
    //配列からデータを取り出し、Cellに書き込む
    NSDictionary *dict = self.collections[(NSUInteger)indexPath.row];
    cell.textLabel.text = [dict objectForKey:@"title"];
    
    return cell;
}

#pragma mark - Datastore APIの呼び出し
- (void)refreshAction:(id)sender
{
    [self.refreshControl beginRefreshing];
    [UIApplication sharedApplication].networkActivityIndicatorVisible = YES;
    
    //FIXME: Datastore API検索のURLを作成（createdAtの昇順で並べる）
    NSString *urlString = @"https://api-datastore.appiaries.com/v1/dat/_sandbox//feed/-;order=createdAt";
    
    //アピアリーズに通信する部分
    NSURLSession *session = [NSURLSession sharedSession];
    NSURL *url = [NSURL URLWithString:urlString];
    NSURLRequest *request = [NSURLRequest requestWithURL:url];
    NSURLSessionTask *task = [session dataTaskWithRequest:request completionHandler:^(NSData *data, NSURLResponse *response, NSError *error) {
        if (error) {
            //通信がエラーの場合
            NSLog(@"=========error=========\n%@",error);
            NSDictionary *userInfo = [error userInfo];
            NSString *errorDescription = [userInfo objectForKey:NSLocalizedDescriptionKey];
            if (errorDescription != nil) {
                UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"error"
                                                                message:errorDescription
                                                               delegate:nil
                                                      cancelButtonTitle:@"OK"
                                                      otherButtonTitles:nil];
                [alert show];
            }
        } else {
            //通信が成功の場合
            NSLog(@"=========success=========\n%@",[[NSString alloc] initWithData:data
                                                                         encoding:NSUTF8StringEncoding]);
            NSError *jsonError = nil;
            NSDictionary *resultJson = [NSJSONSerialization JSONObjectWithData:data
                                                                       options:NSJSONReadingAllowFragments error:&jsonError];
            NSInteger statusCode = ((NSHTTPURLResponse *)response).statusCode;
            if (!jsonError && statusCode == 200) {
                //結果は「_objs」の配列で取得できる
                NSArray *objs = [resultJson objectForKey:@"_objs"];
                
                //ここで配列データを削除
                [self.collections removeAllObjects];
                for (NSDictionary *dict in objs) {
                    //配列にデータを追加
                    [self.collections addObject:dict];
                }
                //テーブルを更新
                [self.tableView reloadData];
            } else {
                //ステータスコードがエラー
                NSLog(@"=========response error=========\n%@", [response description]);
            }
        }
        
        [UIApplication sharedApplication].networkActivityIndicatorVisible = NO;
        [self.refreshControl endRefreshing];
    }];
    [task resume];
}

#pragma mark - Datastore API データ追加処理
-(void)addButtonAction:(id)sender
{
    UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"入力"
                                                    message:@"タイトルを入れて下さい"
                                                   delegate:self
                                          cancelButtonTitle:@"Cancel"
                                          otherButtonTitles:@"OK", nil];
    [alert setAlertViewStyle:UIAlertViewStylePlainTextInput];
    [alert show];
}

-(void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex
{
    if (buttonIndex == 1) {
        NSString *title = [[alertView textFieldAtIndex:0]text]?:@"";
        if ([title length] > 0) {
            [self createData:title];
        }
    }
}

-(void)createData:(NSString*)title
{
    [UIApplication sharedApplication].networkActivityIndicatorVisible = YES;
    //日時
    NSNumber *dateNumber = [NSNumber numberWithUnsignedLong:(unsigned long)[[NSDate date] timeIntervalSince1970]];
    //POSTデータの作成
    NSDictionary *parameters = @{@"title": title,
                                 @"createdAt": dateNumber};
    NSError *jsonError = nil;
    NSData *postData = [NSJSONSerialization dataWithJSONObject:parameters
                                                       options:NSJSONWritingPrettyPrinted
                                                         error:&jsonError];
    //FIXME: Datastore API検索のURLを作成
    NSString *urlString = @"https://api-datastore.appiaries.com/v1/dat/_sandbox//feed?access_token=&proc=create&get=true";
    //アピアリーズに通信する部分
    NSURLSession *session = [NSURLSession sharedSession];
    NSURL *url = [NSURL URLWithString:urlString];
    NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:url];
    [request setHTTPMethod:@"POST"];
    [request setHTTPBody:postData];
    [request setValue:@"application/json" forHTTPHeaderField:@"Content-Type"];
    NSURLSessionTask *task = [session dataTaskWithRequest:request completionHandler:^(NSData *data, NSURLResponse *response, NSError *error) {
        if (error) {
            //通信がエラーの場合
            NSLog(@"=========error=========\n%@",error);
            NSDictionary *userInfo = [error userInfo];
            NSString *errorDescription = [userInfo objectForKey:NSLocalizedDescriptionKey];
            if (errorDescription != nil) {
                UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"error"
                                                                message:errorDescription
                                                               delegate:nil
                                                      cancelButtonTitle:@"OK"
                                                      otherButtonTitles:nil];
                [alert show];
            }
        } else {
            NSInteger statusCode = ((NSHTTPURLResponse *)response).statusCode;
            if (statusCode == 201) {
                //ステータスコードが成功の場合
                NSLog(@"%@",[response description]);
                NSLog(@"=========success=========\n%@",[[NSString alloc] initWithData:data
                                                                             encoding:NSUTF8StringEncoding]);
                dispatch_async(dispatch_get_main_queue(), ^{
                    UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@" "
                                                                    message:@"登録成功!"
                                                                   delegate:nil
                                                          cancelButtonTitle:@"OK"
                                                          otherButtonTitles:nil];
                    [alert show];
                    //データの更新を行う
                    [self refreshAction:nil];
                });
            } else {
                //ステータスコードがエラー
                NSLog(@"=========response error=========\n%@", [response description]);
            }
        }
        
        [UIApplication sharedApplication].networkActivityIndicatorVisible = NO;
    }];
    [task resume];
}

@end
