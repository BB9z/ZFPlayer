//
//  ZFTableViewController.m
//
// Copyright (c) 2016年 任子丰 ( http://github.com/renzifeng )
//
// Permission is hereby granted, free of charge, to any person obtaining a copy
// of this software and associated documentation files (the "Software"), to deal
// in the Software without restriction, including without limitation the rights
// to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
// copies of the Software, and to permit persons to whom the Software is
// furnished to do so, subject to the following conditions:
//
// The above copyright notice and this permission notice shall be included in
// all copies or substantial portions of the Software.
//
// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
// IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
// FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
// AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
// LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
// OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
// THE SOFTWARE.

#import "ZFTableViewController.h"
#import "ZFPlayerCell.h"
#import "ZFPlayerView.h"
#import "ZFPlayerModel.h"

@interface ZFTableViewController ()

@property (nonatomic, strong) NSMutableArray *dataSource;
@property (nonatomic, strong) ZFPlayerView *listPlayer;

@end

@implementation ZFTableViewController

#pragma mark - life Cycle

- (void)viewDidLoad {
    [super viewDidLoad];
    self.tableView.estimatedRowHeight = 44.0f;
    
    self.tableView.rowHeight = UITableViewAutomaticDimension;
    
    self.dataSource = @[].mutableCopy;
    NSString *path = [[NSBundle mainBundle] pathForResource:@"videoData" ofType:@"json"];
    NSData *data = [NSData dataWithContentsOfFile:path];
    NSDictionary *rootDict = [NSJSONSerialization JSONObjectWithData:data options:NSJSONReadingAllowFragments error:nil];
    
    
    NSArray *dailyList = [rootDict objectForKey:@"dailyList"];
    // 使用KVC解析json
    for (NSDictionary *dic in dailyList) {
        NSArray *videoList = [dic objectForKey:@"videoList"];
        NSMutableArray *sectionArray = @[].mutableCopy;
        for (NSDictionary *dataDic in videoList) {
            ZFPlayerModel *model = [[ZFPlayerModel alloc] init];
            [model setValuesForKeysWithDictionary:dataDic];
            [sectionArray addObject:model];
        }
        [self.dataSource addObject:sectionArray];
    }
}

// 页面消失时候
- (void)viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:animated];
    [self.listPlayer resetPlayer];
}

- (void)willRotateToInterfaceOrientation:(UIInterfaceOrientation)toInterfaceOrientation duration:(NSTimeInterval)duration
{
    if (toInterfaceOrientation == UIInterfaceOrientationPortrait) {
        self.view.backgroundColor = [UIColor whiteColor];
    }else if (toInterfaceOrientation == UIInterfaceOrientationLandscapeRight) {
        self.view.backgroundColor = [UIColor blackColor];
    }
}

- (ZFPlayerView *)listPlayer {
    if (_listPlayer) return _listPlayer;
    _listPlayer = [ZFPlayerView new];
    return _listPlayer;
}

#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return self.dataSource.count;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    NSArray * arr = self.dataSource[section];
    return arr.count;
}


- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {

    static NSString *identifier        = @"playerCell";
    ZFPlayerCell *cell                 = [tableView dequeueReusableCellWithIdentifier:identifier];
    // 取到对应cell的model
    __block ZFPlayerModel *model       = self.dataSource[indexPath.section][indexPath.row];
    // 赋值model
    cell.model                         = model;
    
    __weak NSIndexPath *weakIndexPath = indexPath;
    __weak typeof(self) weakSelf = self;
    __weak ZFPlayerCell *weakCell = cell;
    // 点击播放的回调
    cell.playBlock = ^(UIButton *btn){
        NSURL *videoURL     = [NSURL URLWithString:model.playUrl];
        // 设置player相关参数(需要设置imageView的tag值，此处设置的为101)
        [weakSelf.listPlayer setVideoURL:videoURL
                           withTableView:weakSelf.tableView
                             AtIndexPath:weakIndexPath
                        withImageViewTag:101];
        [weakSelf.listPlayer addPlayerToCellImageView:weakCell.picView];
    };

    return cell;
}

- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section {
    NSArray * modelArray = self.dataSource[section];
    ZFPlayerModel *model = modelArray[0];
    return [self getDateFromTimeInterval:model.date];
}

/**
 *  转换时间戳
 *
 *  @param timeInterval 时间戳
 *
 *  @return 时间字符串
 */
- (NSString *)getDateFromTimeInterval:(long)timeInterval {
    NSDateFormatter *formatter = [[NSDateFormatter alloc] init];
    formatter.dateFormat       = @"yyyy年MM月dd日";
    NSDate *createDate         = [NSDate dateWithTimeIntervalSince1970:timeInterval/1000];
    NSString *createStr        = [formatter stringFromDate:createDate];
    return createStr;
}

/*
#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
}
*/

@end
