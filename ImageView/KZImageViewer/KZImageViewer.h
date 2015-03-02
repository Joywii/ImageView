//
//  KZImageViewer.h
//  KuaiZhanNativeApp
//
//  Created by joywii on 14/10/22.
//  Copyright (c) 2014年 sohu. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface KZImageViewer : UIView

- (void)showImages:(NSArray *)imageArray atIndex:(NSInteger)index;

- (void)showImages:(NSArray *)imageArray selectImageView:(UIImageView *)selectImageView atIndex:(NSInteger)index;

@end
