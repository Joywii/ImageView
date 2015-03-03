//
//  ViewController.m
//  ImageViewDemo
//
//  Created by joywii on 15/3/2.
//  Copyright (c) 2015年 joywii. All rights reserved.
//

#import "ViewController.h"
#import "KZImageViewer.h"
#import "KZImage.h"

#define kScreenHeight         [UIScreen mainScreen].bounds.size.height
#define kScreenWidth          [UIScreen mainScreen].bounds.size.width

@interface ViewController ()

@property (nonatomic,strong) NSMutableArray *firstImageArray;

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view, typically from a nib.
    _firstImageArray = [NSMutableArray array];
    
    UILabel *viewImageLabel = [[UILabel alloc] initWithFrame:CGRectMake(10, 50, kScreenWidth - 20, 20)];
    viewImageLabel.backgroundColor = [UIColor clearColor];
    viewImageLabel.text = @"方式一：";
    viewImageLabel.font = [UIFont systemFontOfSize:17];
    viewImageLabel.textColor = [UIColor blackColor];
    [self.view addSubview:viewImageLabel];
    
    CGFloat width = (kScreenWidth - 40) / 3;
    
    for (int i = 0; i < 3; i++) {
        
        CGFloat x = 10;
        CGFloat y = 80;
        x += (i * (10 + width));
        
        UIImageView *imageView = [[UIImageView alloc] initWithFrame:CGRectMake(x, y, width, width)];
        [self.firstImageArray addObject:imageView];
        imageView.image = [UIImage imageNamed:[NSString stringWithFormat:@"%d.jpg",i+1]];//
        imageView.userInteractionEnabled = YES;
        imageView.contentMode = UIViewContentModeScaleAspectFill;
        imageView.clipsToBounds = YES;
        
        UITapGestureRecognizer *gesture = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(firstTapHandle:)];
        [imageView addGestureRecognizer:gesture];
        [self.view addSubview:imageView];
    }
}

//图片快速预览
- (void)firstTapHandle:(UITapGestureRecognizer *)tap
{
    //当前UIImageView 有图片才会显示
    UIImage *currentImage = [(UIImageView *)tap.view image];
    if (!currentImage)
    {
        return;
    }
    
    NSMutableArray  *kzImageArray = [NSMutableArray array];
    for (int i = 0; i < [self.firstImageArray count]; i++)
    {
        UIImageView *imageView = [self.firstImageArray objectAtIndex:i];
        KZImage *kzImage = [[KZImage alloc] initWithImage:imageView.image];
        kzImage.thumbnailImage = imageView.image;
        
        kzImage.srcImageView = imageView;
        [kzImageArray addObject:kzImage];
    }
    KZImageViewer *imageViewer = [[KZImageViewer alloc] init];
    [imageViewer showImages:kzImageArray atIndex:[self.firstImageArray indexOfObject:(UIImageView *)tap.view]];
}

@end
