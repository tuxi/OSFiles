//
//  UIScrollView+NoDataPlaceholder.m
//  NODataPlaceholderView
//
//  Created by Ossey on 2017/5/29.
//  Copyright © 2017年 Ossey. All rights reserved.
//

#import "UIScrollView+NoDataPlaceholder.h"
#import <objc/runtime.h>


////////////////////////////////
static char const * const NoDataPlaceholderViewKey = "NoDataPlaceholderView";
static char const * const NoDataPlaceholderDataSourceKey =     "NoDataPlaceholdeDataSource";
static char const * const NoDataPlaceholderDelegateKey =   "NoDataPlaceholdeDelegate";
static char const * const NoDataPlcaeHolderLoadingKey = "loading";

/////////////////////////////////
/// 存储_impLookupTable中swizzledInfo字典中基类名的key
static NSString * const SwizzleInfoClassKey = @"class";
/// 存储_impLookupTable中swizzledInfo字典中原方法名称的key
static NSString * const SwizzleInfoSelectorKey = @"selector";
/// 存储_impLookupTable中swizzledInfo字典中原方法的新的实现的地址
static NSString *const SwizzleInfoPointerKey = @"pointer";
/// 作为方法查找表使用, key: 类名_方法名 拼接的，value:swizzledInfo字典 (key为上面三个key)
static NSMutableDictionary<NSString *, NSDictionary *> *_impLookupTable;

////////////////////////////////
static NSString * const NoDataPlaceholderBackgroundImageViewAnimationKey = @"NoDataPlaceholderBackgroundImageViewAnimation";

@interface WeakObjectContainer : NSObject

@property (nonatomic, weak, readonly) id weakObject;

- (instancetype)initWithWeakObject:(__weak id)weakObject;

@end

@interface NoDataPlaceholderView : UIView

/** 内容视图 */
@property (nonatomic, weak, readonly) UIView *contentView;
/** 标题label */
@property (nonatomic, weak, readonly) UILabel *titleLabel;
/** 详情label */
@property (nonatomic, weak, readonly) UILabel *detailLabel;
/** 图片视图 */
@property (nonatomic, weak, readonly) UIImageView *imageView;
/** 重新加载的button */
@property (nonatomic, weak, readonly) UIButton *reloadButton;
/** 自定义视图 */
@property (nonatomic, strong) UIView *customView;
/** 点按手势 */
@property (nonatomic, strong) UITapGestureRecognizer *tapGesture;
/** 中心点y的偏移量 */
@property (nonatomic, assign) CGFloat contentOffsetY;
/** 垂直间距 */
@property (nonatomic, assign) CGFloat verticalSpace;
/** 是否淡入淡出显示 */
@property (nonatomic, assign) BOOL fadeInOnDisplay;
/** tap手势回调block */
@property (nonatomic, copy) void (^tapGestureRecognizerBlock)(UITapGestureRecognizer *tap);

/// 设置子控件的约束
- (void)setupConstraints;
/// 准备复用,移除所有子控件及其约束
- (void)prepareForReuse;
/// 设置tap手势
- (void)tapGestureRecognizer:(void (^)(UITapGestureRecognizer *))tapBlock;

@end

@interface UIScrollView () <UIGestureRecognizerDelegate>

@property (nonatomic, readonly) NoDataPlaceholderView *noDataPlaceholderView;

@property (nonatomic, copy) NoDataPlaceholderContentViewAttribute noDataPlaceholderContentViewAttribute;

@end

@implementation UIScrollView (NoDataPlaceholder)


#pragma mark - get

- (NoDataPlaceholderView *)noDataPlaceholderView {
    
    NoDataPlaceholderView *view = objc_getAssociatedObject(self, NoDataPlaceholderViewKey);
    
    if (view == nil) {
        view = [NoDataPlaceholderView new];
        view.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
        view.hidden = YES;
        view.tapGesture.delegate = self;
        __weak typeof(self) weakSelf = self;
        [view tapGestureRecognizer:^(UITapGestureRecognizer *tap) {
            [weakSelf xy_didTapContentView:tap];
        }];
        self.noDataPlaceholderView = view;
    }
    
    return view;
}

- (id<NoDataPlaceholderDataSource>)noDataPlaceholderDataSource {
    WeakObjectContainer *container = objc_getAssociatedObject(self, NoDataPlaceholderDataSourceKey);
    return container.weakObject;
}

- (id<NoDataPlaceholderDelegate>)noDataPlaceholderDelegate {
    WeakObjectContainer *container = objc_getAssociatedObject(self, NoDataPlaceholderDelegateKey);
    return container.weakObject;
}

- (BOOL)isNoDatasetVisible {
    UIView *view = objc_getAssociatedObject(self, NoDataPlaceholderViewKey);
    return view ? !view.hidden : NO;
}

- (BOOL)isLoading {
    return [objc_getAssociatedObject(self, NoDataPlcaeHolderLoadingKey) boolValue];
}

- (NoDataPlaceholderContentViewAttribute)noDataPlaceholderContentViewAttribute {
    return objc_getAssociatedObject(self, @selector(noDataPlaceholderContentViewAttribute));
}


#pragma mark - set

- (void)setNoDataPlaceholderDataSource:(id<NoDataPlaceholderDataSource>)noDataPlaceholderDataSource {
    if (!noDataPlaceholderDataSource || ![self xy_noDataPlacehodler_canDisplay]) {
        [self xy_noDataPlacehodler_invalidate];
    }
    
    WeakObjectContainer *container = [[WeakObjectContainer alloc] initWithWeakObject:noDataPlaceholderDataSource];
    objc_setAssociatedObject(self, NoDataPlaceholderDataSourceKey, container, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
    
    // reloadData方法的实现进行处理
    [self swizzleIfPossible:@selector(reloadData)];
    
    if ([self isKindOfClass:[UITableView class]]) {
        [self swizzleIfPossible:@selector(endUpdates)];
    }
}


- (void)setNoDataPlaceholderDelegate:(id<NoDataPlaceholderDelegate>)noDataPlaceholderDelegate {
    if (noDataPlaceholderDelegate == nil) {
        [self xy_noDataPlacehodler_invalidate];
    }
    WeakObjectContainer *container = [[WeakObjectContainer alloc] initWithWeakObject:noDataPlaceholderDelegate];
    objc_setAssociatedObject(self, NoDataPlaceholderDelegateKey, container, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}

- (void)setNoDataPlaceholderView:(NoDataPlaceholderView *)noDataPlaceholderView {
    objc_setAssociatedObject(self, NoDataPlaceholderViewKey, noDataPlaceholderView, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}

- (void)setLoading:(BOOL)loading {
    
    if (self.loading == loading) {
        return;
    }
    
    objc_setAssociatedObject(self, NoDataPlcaeHolderLoadingKey, @(loading), OBJC_ASSOCIATION_RETAIN_NONATOMIC);
    
    // 这里最好还是别干预reloadData,只刷新NoDataView
    [self reloadNoDataView];
    
    //    if ([self respondsToSelector:@selector(reloadData)]) {
    //        [self performSelector:@selector(reloadData)];
    //    } else {
    //        [self reloadNoDataView];
    //    }
}

- (void)setNoDataPlaceholderContentViewAttribute:(NoDataPlaceholderContentViewAttribute)noDataPlaceholderContentViewAttribute {
    objc_setAssociatedObject(self, @selector(noDataPlaceholderContentViewAttribute), noDataPlaceholderContentViewAttribute, OBJC_ASSOCIATION_COPY_NONATOMIC);
}

#pragma mark -

/// 点击NODataPlaceholderView contentView的回调
- (void)xy_didTapContentView:(UITapGestureRecognizer *)tap {
    if (self.noDataPlaceholderDelegate && [self.noDataPlaceholderDelegate respondsToSelector:@selector(noDataPlaceholder:didTapOnContentView:)]) {
        [self.noDataPlaceholderDelegate noDataPlaceholder:self didTapOnContentView:tap];
    }
}

- (void)xy_clickReloadBtn:(UIButton *)btn {
    if (self.noDataPlaceholderDelegate && [self.noDataPlaceholderDelegate respondsToSelector:@selector(noDataPlaceholder:didClickReloadButton:)]) {
        [self.noDataPlaceholderDelegate noDataPlaceholder:self didClickReloadButton:btn];
    }
}

#pragma makr - delegate private api

// 是否需要淡入淡出
- (BOOL)xy_noDataPlacehodler_shouldFadeInOnDisplay {
    if (self.noDataPlaceholderDelegate && [self.noDataPlaceholderDelegate respondsToSelector:@selector(noDataPlaceholderShouldFadeInOnDisplay:)]) {
        return [self.noDataPlaceholderDelegate noDataPlaceholderShouldFadeInOnDisplay:self];
    }
    return YES;
}

// 是否符合显示
- (BOOL)xy_noDataPlacehodler_canDisplay {
    if (self.noDataPlaceholderDataSource && [self.noDataPlaceholderDataSource conformsToProtocol:@protocol(NoDataPlaceholderDataSource) ]) {
        if ([self isKindOfClass:[UITableView class]] || [self isKindOfClass:[UICollectionView class]] || [self isKindOfClass:[UIScrollView class]]) {
            return YES;
        }
    }
    return NO;
}

// 获取UITableView或UICollectionView的所有item的总数
- (NSInteger)xy_itemCount {
    NSInteger itemCount = 0;
    
    // UIScrollView 没有dataSource属性, 所以返回0
    if (![self respondsToSelector:@selector(dataSource)]) {
        return itemCount;
    }
    
    // UITableView
    if ([self isKindOfClass:[UITableView class]]) {
        UITableView *tableView = (UITableView *)self;
        id<UITableViewDataSource> dataSource = tableView.dataSource;
        
        NSInteger sections = 1;
        if (dataSource && [dataSource respondsToSelector:@selector(numberOfSectionsInTableView:)]) {
            sections = [dataSource numberOfSectionsInTableView:tableView];
        }
        if (dataSource && [dataSource respondsToSelector:@selector(tableView:numberOfRowsInSection:)]) {
            // 遍历所有组获取每组的行数，就相加得到所有item的个数，一行就是一个item
            for (NSInteger section = 0; section < sections; ++section) {
                itemCount += [dataSource tableView:tableView numberOfRowsInSection:section];
            }
        }
    }
    
    // UICollectionView
    if ([self isKindOfClass:[UICollectionView class]]) {
        UICollectionView *collectionView = (UICollectionView *)self;
        id<UICollectionViewDataSource> dataSource = collectionView.dataSource;
        
        NSInteger sections = 1;
        if (dataSource && [dataSource respondsToSelector:@selector(numberOfSectionsInCollectionView:)]) {
            sections = [dataSource numberOfSectionsInCollectionView:collectionView];
        }
        if (dataSource && [dataSource respondsToSelector:@selector(collectionView:numberOfItemsInSection:)]) {
            // 遍历所有组获取每组的行数，就相加得到所有item的个数，一行就是一个item
            for (NSInteger section = 0; section < sections; ++section) {
                itemCount += [dataSource collectionView:collectionView numberOfItemsInSection:section];
            }
        }
    }
    
    return itemCount;
}

/// 是否应该显示
- (BOOL)xy_noDataPlacehodler_shouldDisplay {
    if (self.noDataPlaceholderDelegate && [self.noDataPlaceholderDelegate respondsToSelector:@selector(noDataPlaceholderShouldDisplay:)]) {
        return [self.noDataPlaceholderDelegate noDataPlaceholderShouldDisplay:self];
    }
    return YES;
}

/// 是否应该强制显示,默认不需要的
- (BOOL)xy_noDataPlacehodler_shouldBeForcedToDisplay {
    if (self.noDataPlaceholderDelegate && [self.noDataPlaceholderDelegate respondsToSelector:@selector(noDataPlaceholderShouldBeForcedToDisplay:)]) {
        return [self.noDataPlaceholderDelegate noDataPlaceholderShouldBeForcedToDisplay:self];
    }
    return NO;
}

- (void)xy_noDataPlacehodler_noDataPlaceholderViewWillAppear {
    if (self.noDataPlaceholderDelegate && [self.noDataPlaceholderDelegate respondsToSelector:@selector(noDataPlaceholderWillAppear:)]) {
        [self.noDataPlaceholderDelegate noDataPlaceholderWillAppear:self];
    }
}

/// 是否允许响应事件
- (BOOL)xy_noDataPlacehodler_isAllowedResponseEvent {
    if (self.noDataPlaceholderDelegate && [self.noDataPlaceholderDelegate respondsToSelector:@selector(noDataPlaceholderShouldAllowResponseEvent:)]) {
        return [self.noDataPlaceholderDelegate noDataPlaceholderShouldAllowResponseEvent:self];
    }
    return YES;
}

/// 是否运行滚动
- (BOOL)xy_noDataPlacehodler_isAllowedScroll  {
    if (self.noDataPlaceholderDelegate && [self.noDataPlaceholderDelegate respondsToSelector:@selector(noDataPlaceholderShouldAllowScroll:)]) {
        return [self.noDataPlaceholderDelegate noDataPlaceholderShouldAllowScroll:self];
    }
    return NO;
}

/// 是否运行imageView展示动画
- (BOOL)xy_noDataPlacehodler_isAllowedImageViewAnimate {
    if (self.noDataPlaceholderDelegate && [self.noDataPlaceholderDelegate respondsToSelector:@selector(noDataPlaceholderShouldAnimateImageView:)]) {
        return [self.noDataPlaceholderDelegate noDataPlaceholderShouldAnimateImageView:self];
    }
    return NO;
}

- (void)xy_noDataPlacehodler_didAppear {
    if (self.noDataPlaceholderDelegate && [self.noDataPlaceholderDelegate respondsToSelector:@selector(noDataPlaceholderDidAppear:)]) {
        [self.noDataPlaceholderDelegate noDataPlaceholderDidAppear:self];
    }
}

- (void)xy_noDataPlacehodler_willDisappear {
    if (self.noDataPlaceholderDelegate && [self.noDataPlaceholderDelegate respondsToSelector:@selector(noDataPlaceholderWillDisappear:)]) {
        [self.noDataPlaceholderDelegate noDataPlaceholderWillDisappear:self];
    }
}

- (void)xy_noDataPlacehodler_didDisappear {
    if (self.noDataPlaceholderDelegate && [self.noDataPlaceholderDelegate respondsToSelector:@selector(noDataPlaceholderDidDisappear:)]) {
        [self.noDataPlaceholderDelegate noDataPlaceholderDidDisappear:self];
    }
}



#pragma mark - DataSource privete api

- (UIView *)xy_noDataPlacehodler_customView {
    if (self.noDataPlaceholderDataSource && [self.noDataPlaceholderDataSource respondsToSelector:@selector(customViewForNoDataPlaceholder:)]) {
        UIView *view = [self.noDataPlaceholderDataSource customViewForNoDataPlaceholder:self];
        if (view) {
            NSAssert([view isKindOfClass:[UIView class]], @"-[customViewForNoDataPlaceholder:] 返回值必须为UIView类或其子类");
            return view;
        }
    }
    return nil;
}

- (NSAttributedString *)xy_noDataPlacehodler_titleLabelString {
    if (self.noDataPlaceholderDataSource && [self.noDataPlaceholderDataSource respondsToSelector:@selector(titleAttributedStringForNoDataPlaceholder:)]) {
        NSAttributedString *string = [self.noDataPlaceholderDataSource titleAttributedStringForNoDataPlaceholder:self];
        if (string) {
            NSAssert([string isKindOfClass:[NSAttributedString class]], @"-[titleAttributedStringForNoDataPlaceholder:] 返回值必须是有效的NSAttributedString类型");
            return string;
        }
    }
    return nil;
}

- (NSAttributedString *)xy_noDataPlacehodler_detailLabelString {
    if (self.noDataPlaceholderDataSource && [self.noDataPlaceholderDataSource respondsToSelector:@selector(detailAttributedStringForNoDataPlaceholder:)]) {
        NSAttributedString *string = [self.noDataPlaceholderDataSource detailAttributedStringForNoDataPlaceholder:self];
        if (string) {
            NSAssert([string isKindOfClass:[NSAttributedString class]], @"-[detailAttributedStringForNoDataPlaceholder:]返回值必须是有效的NSAttributedString类型");
            return string;
        }
    }
    return nil;
}

- (UIImage *)xy_noDataPlacehodler_Image {
    if (self.noDataPlaceholderDataSource && [self.noDataPlaceholderDataSource respondsToSelector:@selector(imageForNoDataPlaceholder:)]) {
        UIImage *image = [self.noDataPlaceholderDataSource imageForNoDataPlaceholder:self];
        if (image) {
            NSAssert([image isKindOfClass:[UIImage class]], @"-[imageForNoDataPlaceholder:]返回值必须是UIImage类型");
            return image;
        }
    }
    return nil;
}

- (CAAnimation *)xy_noDataPlacehodler_imageAnimation {
    if (self.noDataPlaceholderDataSource && [self.noDataPlaceholderDataSource respondsToSelector:@selector(imageAnimationForNoDataPlaceholder:)]) {
        CAAnimation *imageAnimation = [self.noDataPlaceholderDataSource imageAnimationForNoDataPlaceholder:self];
        if (imageAnimation) {
            NSAssert([imageAnimation isKindOfClass:[CAAnimation class]], @"-[imageAnimationForNoDataPlaceholder:]返回值必须为CAAnimation类型");
            return imageAnimation;
        }
    }
    return nil;
}

- (UIColor *)xy_noDataPlacehodler_imageTintColor {
    if (self.noDataPlaceholderDataSource && [self.noDataPlaceholderDataSource respondsToSelector:@selector(imageTintColorForNoDataPlaceholder:)]) {
        UIColor *color = [self.noDataPlaceholderDataSource imageTintColorForNoDataPlaceholder:self];
        if (color) NSAssert([color isKindOfClass:[UIColor class]], @"-[imageTintColorForNoDataPlaceholder:]返回值必须是有效的UIColor类型");
        return color;
    }
    return nil;
}

- (NSAttributedString *)xy_noDataPlacehodler_reloadButtonTitleForState:(UIControlState)state {
    if (self.noDataPlaceholderDataSource && [self.noDataPlaceholderDataSource respondsToSelector:@selector(reloadbuttonTitleAttributedStringForNoDataPlaceholder:forState:)]) {
        NSAttributedString *string = [self.noDataPlaceholderDataSource reloadbuttonTitleAttributedStringForNoDataPlaceholder:self forState:state];
        if (string) {
            NSAssert([string isKindOfClass:[NSAttributedString class]], @"-[reloadbuttonTitleAttributedStringForNoDataPlaceholder:forState:]返回值必须为NSAttributedString类型");
            return string;
            
        }
    }
    return nil;
}

- (UIImage *)xy_noDataPlacehodler_reloadButtonImageForState:(UIControlState)state {
    if (self.noDataPlaceholderDataSource && [self.noDataPlaceholderDataSource respondsToSelector:@selector(reloadButtonImageForNoDataPlaceholder:forState:)]) {
        UIImage *image = [self.noDataPlaceholderDataSource reloadButtonImageForNoDataPlaceholder:self forState:state];
        if (image) {
            NSAssert([image isKindOfClass:[UIImage class]], @"-[reloadButtonImageForNoDataPlaceholder:forState:]返回值必须为UIImage类型");
            return image;
        }
    }
    return nil;
}

- (UIImage *)xy_noDataPlacehodler_reloadButtonBackgroundImageForState:(UIControlState)state {
    if (self.noDataPlaceholderDataSource && [self.noDataPlaceholderDataSource respondsToSelector:@selector(reloadButtonBackgroundImageForNoDataPlaceholder:forState:)]) {
        UIImage *image = [self.noDataPlaceholderDataSource reloadButtonBackgroundImageForNoDataPlaceholder:self forState:state];
        if (image) {
            NSAssert([image isKindOfClass:[UIImage class]], @"-[reloadButtonBackgroundImageForNoDataPlaceholder:forState:]返回值必须为UIImage类型");
            return image;
            
        }
        
    }
    return nil;
}

- (UIColor *)xy_noDataPlacehodler_backgroundColor {
    if (self.noDataPlaceholderDataSource && [self.noDataPlaceholderDataSource respondsToSelector:@selector(backgroundColorForNoDataPlaceholder:)]) {
        UIColor *color = [self.noDataPlaceholderDataSource backgroundColorForNoDataPlaceholder:self];
        if (color) {
            NSAssert([color isKindOfClass:[UIColor class]], @"-[backgroundColorForNoDataPlaceholder:]返回值必须为UIColor");
            return color;
        }
    }
    return [UIColor clearColor];
}

- (UIColor *)xy_noDataPlacehodler_reloadButtonBackgroundColor {
    if (self.noDataPlaceholderDataSource && [self.noDataPlaceholderDataSource respondsToSelector:@selector(reloadButtonBackgroundColorForNoDataPlaceholder:)]) {
        UIColor *color = [self.noDataPlaceholderDataSource reloadButtonBackgroundColorForNoDataPlaceholder:self];
        if (color) {
            NSAssert([color isKindOfClass:[UIColor class]], @"-[reloadButtonBackgroundColorForNoDataPlaceholder:]返回值必须为UIColor");
            return color;
        }
    }
    return [UIColor clearColor];
}

- (CGFloat)xy_noDataPlacehodler_verticalSpace {
    if (self.noDataPlaceholderDataSource && [self.noDataPlaceholderDataSource respondsToSelector:@selector(contentSubviewsVerticalSpaceFoNoDataPlaceholder:)]) {
        return [self.noDataPlaceholderDataSource contentSubviewsVerticalSpaceFoNoDataPlaceholder:self];
    }
    return 0.0;
}

- (CGFloat)xy_noDataPlacehodler_contentOffsetY {
    CGFloat offset = 0.0;
    
    if (self.noDataPlaceholderDataSource && [self.noDataPlaceholderDataSource respondsToSelector:@selector(contentOffsetYForNoDataPlaceholder:)]) {
        offset = [self.noDataPlaceholderDataSource contentOffsetYForNoDataPlaceholder:self];
    }
    return offset;
}

#pragma MARK - public

- (void)reloadNoDataView {
    [self xy_reloadNoDataView];
}


#pragma mark - Method Swizzling

- (void)swizzleIfPossible:(SEL)selector {
    
    // 检测这个方法是否实现
    if (![self respondsToSelector:selector]) {
        return;
    }
    
    if (_impLookupTable == nil) {
        // 支持3个基类 UITableView UICollectionView UIScrollView
        _impLookupTable = [NSMutableDictionary  dictionaryWithCapacity:3];
    }
    
    // 确保setImplementation 在UITableView or UICollectionView只调用一次
    for (NSDictionary *info in [_impLookupTable allValues]) {
        Class clas = [info objectForKey:SwizzleInfoClassKey];
        NSString *selectorName = [info objectForKey:SwizzleInfoSelectorKey];
        
        // 当当前类已经lookup了，就返回
        if ([selectorName isEqualToString:NSStringFromSelector(selector)]) {
            if ([self isKindOfClass:clas]) {
                return;
            }
        }
    }
    
    // 检查当前类的基类：UITableView  UICollectionView  UIScrollView
    Class baseClas = xy_baseClassToSwizzleForTarget(self);
    NSString *key = xy_implementationKey(baseClas, selector);
    NSDictionary *info = [_impLookupTable objectForKey:key];
    NSValue *implValue = [info valueForKey:SwizzleInfoPointerKey];
    
    // 如果该类的实现已经存在，就return
    if (implValue || !key || !baseClas) {
        return;
    }
    
    // 注入额外的实现
    Method method = class_getInstanceMethod(baseClas, selector);
    // 设置这个方法的实现
    IMP newImpl = method_setImplementation(method, (IMP)xy_orginal_implementation);
    
    // 将新实现存储在_impLookupTable(查找表)中
    NSDictionary *swizzleInfo = @{SwizzleInfoClassKey: baseClas, SwizzleInfoSelectorKey: NSStringFromSelector(selector), SwizzleInfoPointerKey: [NSValue valueWithPointer:newImpl]};
    [_impLookupTable setObject:swizzleInfo forKey:key];
}

/// 检查当前类是否符合，符合就返回当前类的基类，不符合返回nil
/// 只能关联这三个类或其子类的， 基类为：UITableView  UICollectionView  UIScrollView
Class xy_baseClassToSwizzleForTarget(id target) {
    if ([target isKindOfClass:[UITableView class]]) {
        return [UITableView class];
    }
    if ([target isKindOfClass:[UICollectionView class]]) {
        return [UICollectionView class];
    }
    if ([target isKindOfClass:[UIScrollView class]]) {
        return [UIScrollView class];
    }
    return nil;
}


/// 根据类名和方法，拼接字符串，作为_impLookupTable的key
NSString * xy_implementationKey(Class clas, SEL selector) {
    if (clas == nil || selector == nil) {
        return nil;
    }
    
    NSString *className = NSStringFromClass(clas);
    NSString *selectorName = NSStringFromSelector(selector);
    return [NSString stringWithFormat:@"%@_%@", className, selectorName];
}

// 对原方法的实现进行加工
void xy_orginal_implementation(id self, SEL _cmd) {
    // 从查找表中获取原始实现
    Class baseCls = xy_baseClassToSwizzleForTarget(self);
    NSString *key = xy_implementationKey(baseCls, _cmd);
    
    NSDictionary *swizzleInfo = [_impLookupTable objectForKey:key];
    NSValue *implValue = [swizzleInfo valueForKey:SwizzleInfoPointerKey];
    
    // 原方法的实现
    IMP impPointer = [implValue pointerValue];
    
    // 为加载NODataPlaceholderView时注入额外的实现
    // 当它在调用原来的执行的方法时并及时更新 'isNoDatasetVisible'属性的值
    [self xy_reloadNoDataView];
    
    // 如果找到原实现，就调用原实现
    if (impPointer) {
        ((void(*)(id, SEL))impPointer)(self, _cmd);
    }
}

#pragma mark - UIGestureRecognizerDelegate


- (BOOL)gestureRecognizerShouldBegin:(UIGestureRecognizer *)gestureRecognizer {
    if ([gestureRecognizer.view isEqual:self.noDataPlaceholderView]) {
        return [self xy_noDataPlacehodler_isAllowedResponseEvent];
    }
    
    return [super gestureRecognizerShouldBegin:gestureRecognizer];
}

- (BOOL)gestureRecognizer:(UIGestureRecognizer *)gestureRecognizer shouldRecognizeSimultaneouslyWithGestureRecognizer:(UIGestureRecognizer *)otherGestureRecognizer {
    UIGestureRecognizer *tapGesture = self.noDataPlaceholderView.tapGesture;
    
    if ([gestureRecognizer isEqual:tapGesture] || [otherGestureRecognizer isEqual:tapGesture]) {
        return YES;
    }
    
    if ( (self.noDataPlaceholderDelegate != (id)self) && [self.noDataPlaceholderDelegate respondsToSelector:@selector(gestureRecognizer:shouldRecognizeSimultaneouslyWithGestureRecognizer:)]) {
        return [(id)self.noDataPlaceholderDelegate gestureRecognizer:gestureRecognizer shouldRecognizeSimultaneouslyWithGestureRecognizer:otherGestureRecognizer];
    }
    
    return NO;
}



#pragma mark - Private methods

// 刷新NoDataPlaceholderView 当调用reloadData时也会调用此方法
- (void)xy_reloadNoDataView {
    
    if (![self xy_noDataPlacehodler_canDisplay]) {
        return;
    }
    
    if (([self xy_noDataPlacehodler_shouldDisplay] && [self xy_itemCount] == 0) || [self xy_noDataPlacehodler_shouldBeForcedToDisplay]) {
        
        // 通知代理即将显示
        [self xy_noDataPlacehodler_noDataPlaceholderViewWillAppear];
        
        NoDataPlaceholderView *noDataPlaceholderView = self.noDataPlaceholderView;
        // 设置是否需要淡入淡出效果
        noDataPlaceholderView.fadeInOnDisplay = [self xy_noDataPlacehodler_shouldFadeInOnDisplay];
        
        if (noDataPlaceholderView.superview == nil) {
            if (([self isKindOfClass:[UITableView class]] || [self isKindOfClass:[UICollectionView class]]) && [self.subviews count] > 1) {
                [self insertSubview:noDataPlaceholderView atIndex:0];
            } else {
                [self addSubview:noDataPlaceholderView];
            }
        }
        
        // 重置视图及其约束对于保证良好状态
        [noDataPlaceholderView prepareForReuse];
        
        UIView *customView = [self xy_noDataPlacehodler_customView];
        if (customView) {
            noDataPlaceholderView.customView = customView;
        } else {
            
            // customView为nil时，则从dataSource中设置到默认的contentView
            
            if (self.noDataPlaceholderContentViewAttribute) {
                self.noDataPlaceholderContentViewAttribute(noDataPlaceholderView.reloadButton, noDataPlaceholderView.titleLabel, noDataPlaceholderView.detailLabel, noDataPlaceholderView.imageView);
            } else {
                NSAttributedString *titleLabelString = [self xy_noDataPlacehodler_titleLabelString];
                NSAttributedString *detailLabelString = [self xy_noDataPlacehodler_detailLabelString];
                
                NSAttributedString *reloadBtnTitle = [self xy_noDataPlacehodler_reloadButtonTitleForState:UIControlStateNormal];
                UIImage *reloadBtnImage = [self xy_noDataPlacehodler_reloadButtonImageForState:UIControlStateNormal];
                
                UIImage *image = [self xy_noDataPlacehodler_Image];
                UIColor *imageTintColor = [self xy_noDataPlacehodler_imageTintColor];
                UIImageRenderingMode renderingMode = imageTintColor ? UIImageRenderingModeAlwaysTemplate : UIImageRenderingModeAlwaysOriginal;
                
                
                // 设置ImageView
                if (image) {
                    noDataPlaceholderView.imageView.image = [image imageWithRenderingMode:renderingMode];
                    noDataPlaceholderView.imageView.tintColor = imageTintColor;
                    
                }
                // 设置imageView的动画
                if ([self xy_noDataPlacehodler_isAllowedImageViewAnimate]) {
                    CAAnimation *animation = [self xy_noDataPlacehodler_imageAnimation];
                    
                    if (animation) {
                        [noDataPlaceholderView.imageView.layer addAnimation:animation forKey:NoDataPlaceholderBackgroundImageViewAnimationKey];
                    }
                } else if ([noDataPlaceholderView.imageView.layer animationForKey:NoDataPlaceholderBackgroundImageViewAnimationKey]) {
                    [noDataPlaceholderView.imageView.layer removeAnimationForKey:NoDataPlaceholderBackgroundImageViewAnimationKey];
                }
                
                if (titleLabelString) {
                    noDataPlaceholderView.titleLabel.attributedText = titleLabelString;
                }
                
                // 设置detailLabel
                if (detailLabelString) {
                    noDataPlaceholderView.detailLabel.attributedText = detailLabelString;
                }
                
                // 设置reloadButton
                [noDataPlaceholderView.reloadButton setBackgroundColor:[self xy_noDataPlacehodler_reloadButtonBackgroundColor]];
                if (reloadBtnImage) {
                    [noDataPlaceholderView.reloadButton setImage:reloadBtnImage forState:UIControlStateNormal];
                    [noDataPlaceholderView.reloadButton setImage:[self xy_noDataPlacehodler_reloadButtonImageForState:UIControlStateHighlighted] forState:UIControlStateHighlighted];
                } else if (reloadBtnTitle) {
                    [noDataPlaceholderView.reloadButton setAttributedTitle:reloadBtnTitle forState:UIControlStateNormal];
                    [noDataPlaceholderView.reloadButton setAttributedTitle:[self xy_noDataPlacehodler_reloadButtonTitleForState:UIControlStateHighlighted] forState:UIControlStateHighlighted];
                    [noDataPlaceholderView.reloadButton setBackgroundImage:[self xy_noDataPlacehodler_reloadButtonBackgroundImageForState:UIControlStateNormal] forState:UIControlStateNormal];
                    [noDataPlaceholderView.reloadButton setBackgroundImage:[self xy_noDataPlacehodler_reloadButtonBackgroundImageForState:UIControlStateHighlighted] forState:UIControlStateHighlighted];
                }
                
            }
            
            // 设置noDataPlaceholderView子控件垂直间的间距
            noDataPlaceholderView.verticalSpace = [self xy_noDataPlacehodler_verticalSpace];
            
        }
        
        
        noDataPlaceholderView.contentOffsetY = [self xy_noDataPlacehodler_contentOffsetY];
        
        noDataPlaceholderView.backgroundColor = [self xy_noDataPlacehodler_backgroundColor];
        noDataPlaceholderView.hidden = NO;
        noDataPlaceholderView.clipsToBounds = YES;
        
        noDataPlaceholderView.userInteractionEnabled = [self xy_noDataPlacehodler_isAllowedResponseEvent];
        
        [noDataPlaceholderView setupConstraints];
        
        // 此方法会先检查动画当前是否启用，然后禁止动画，执行block块语句
        [UIView performWithoutAnimation:^{
            [noDataPlaceholderView layoutIfNeeded];
        }];
        
        self.scrollEnabled = [self xy_noDataPlacehodler_isAllowedScroll];
        
        // 通知代理完全显示
        [self xy_noDataPlacehodler_didAppear];
        
    } else if (self.isNoDatasetVisible) {
        [self xy_noDataPlacehodler_invalidate];
    }
    
}

- (void)xy_noDataPlacehodler_invalidate {
    // 通知代理即将消失
    [self xy_noDataPlacehodler_willDisappear];
    
    if (self.noDataPlaceholderView) {
        [self.noDataPlaceholderView prepareForReuse];
        [self.noDataPlaceholderView removeFromSuperview];
        
        [self setNoDataPlaceholderView:nil];
    }
    
    self.scrollEnabled = YES;
    
    // 通知代理完全消失
    [self xy_noDataPlacehodler_didDisappear];
}

@end

@interface UIView (ConstraintBasedLayoutExtensions)

/// 创建视图的约束
- (NSLayoutConstraint *)equallyRelatedConstraintWithView:(UIView *)view
                                               attribute:(NSLayoutAttribute)attribute;

@end

@implementation NoDataPlaceholderView

@synthesize
contentView = _contentView,
titleLabel = _titleLabel,
detailLabel = _detailLabel,
imageView = _imageView,
reloadButton = _reloadButton,
customView = _customView;

#pragma mark - init

- (instancetype)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        [self setup];
    }
    return self;
}

- (instancetype)initWithCoder:(NSCoder *)coder
{
    self = [super initWithCoder:coder];
    if (self) {
        [self setup];
    }
    return self;
}

- (void)setup {
    [self contentView];
}

- (void)didMoveToSuperview {
    CGRect superviewBounds = self.superview.bounds;
    self.frame = CGRectMake(0.0, 0.0, CGRectGetWidth(superviewBounds), CGRectGetHeight(superviewBounds));
    // 当需要淡入淡出时结合动画执行
    void (^fadeInBlock)(void) = ^{
        _contentView.alpha = 1.0;
    };
    
    if (self.fadeInOnDisplay) {
        [UIView animateWithDuration:0.35 animations:fadeInBlock];
    } else {
        fadeInBlock();
    }
}

#pragma mark - get
- (UIView *)contentView {
    if (_contentView == nil) {
        UIView *contentView = [UIView new];
        contentView.translatesAutoresizingMaskIntoConstraints = NO;
        contentView.backgroundColor = [UIColor clearColor];
        contentView.userInteractionEnabled = YES;
        contentView.alpha = 0;
        contentView.accessibilityIdentifier = @"no data placeholder contentView";
        _contentView = contentView;
        [self addSubview:contentView];
    }
    return _contentView;
}

- (UIImageView *)imageView {
    if (_imageView == nil) {
        UIImageView *imageView = [UIImageView new];
        imageView.translatesAutoresizingMaskIntoConstraints = NO;
        imageView.backgroundColor = [UIColor clearColor];
        imageView.contentMode = UIViewContentModeScaleAspectFit;
        imageView.userInteractionEnabled = NO;
        _imageView = imageView;
        _imageView.accessibilityIdentifier = @"no data placeholder image view";
        [[self contentView] addSubview:_imageView];
    }
    return _imageView;
}

- (UILabel *)titleLabel {
    if (_titleLabel == nil) {
        UILabel *titleLabel = [UILabel new];
        titleLabel.translatesAutoresizingMaskIntoConstraints = NO;
        titleLabel.backgroundColor = [UIColor clearColor];
        titleLabel.font = [UIFont systemFontOfSize:27.0];
        titleLabel.textColor = [UIColor colorWithWhite:0.6 alpha:1.0];
        titleLabel.textAlignment = NSTextAlignmentCenter;
        titleLabel.lineBreakMode = NSLineBreakByWordWrapping;
        titleLabel.numberOfLines = 0;
        // 通过accessibilityIdentifier来定位元素,相当于这个控件的id
        titleLabel.accessibilityIdentifier = @"no data placeholder title";
        _titleLabel = titleLabel;
        
        [[self contentView] addSubview:_titleLabel];
    }
    return _titleLabel;
}

- (UILabel *)detailLabel {
    if (_detailLabel == nil) {
        UILabel *detailLabel = [UILabel new];
        detailLabel.translatesAutoresizingMaskIntoConstraints = NO;
        detailLabel.backgroundColor = [UIColor clearColor];
        
        detailLabel.font = [UIFont systemFontOfSize:17.0];
        detailLabel.textColor = [UIColor colorWithWhite:0.6 alpha:1.0];
        detailLabel.textAlignment = NSTextAlignmentCenter;
        detailLabel.lineBreakMode = NSLineBreakByWordWrapping;
        detailLabel.numberOfLines = 0;
        detailLabel.accessibilityIdentifier = @"no data placeholder detail label";
        _detailLabel = detailLabel;
        
        [[self contentView] addSubview:_detailLabel];
    }
    return _detailLabel;
}

- (UIButton *)reloadButton {
    if (_reloadButton == nil) {
        UIButton *btn = [UIButton buttonWithType:UIButtonTypeCustom];
        btn.translatesAutoresizingMaskIntoConstraints = NO;
        btn.backgroundColor = [UIColor clearColor];
        // 按钮内部控件垂直对齐方式为中心
        btn.contentVerticalAlignment = UIControlContentHorizontalAlignmentCenter;
        btn.contentHorizontalAlignment = UIControlContentHorizontalAlignmentCenter;
        [btn addTarget:self action:@selector(clickReloadBtn:) forControlEvents:UIControlEventTouchUpInside];
        _reloadButton = btn;
        [[self contentView] addSubview:btn];
    }
    return _reloadButton;
}

- (UITapGestureRecognizer *)tapGesture {
    if (_tapGesture == nil) {
        _tapGesture = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(tapGestureOnSelf:)];
        [self addGestureRecognizer:_tapGesture];
    }
    return _tapGesture;
}


- (BOOL)canShowImage {
    return _imageView.image && _imageView.superview;
}

- (BOOL)canShowTitle {
    return _titleLabel.text.length > 0 && _titleLabel.superview;
}

- (BOOL)canShowDetail {
    return _detailLabel.text.length > 0 && _detailLabel.superview;
}

- (BOOL)canShowReloadButton {
    if ([_reloadButton titleForState:UIControlStateNormal] || [_reloadButton attributedTitleForState:UIControlStateNormal].string.length > 0 || [_reloadButton imageForState:UIControlStateNormal]) {
        return _reloadButton.superview != nil;
    }
    return NO;
}

#pragma mark - set

- (void)setCustomView:(UIView *)customView {
    if (!customView) {
        return;
    }
    
    if (_customView) {
        [_customView removeFromSuperview];
        _customView = nil;
    }
    
    _customView = customView;
    _customView.translatesAutoresizingMaskIntoConstraints = NO;
    _customView.accessibilityIdentifier = @"no data placeholder custom view";
    [self.contentView addSubview:_customView];
}


- (void)tapGestureRecognizer:(void (^)(UITapGestureRecognizer *))tapBlock {
    
    if (!self.tapGesture) {
        self.tapGesture = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(tapGestureOnSelf:)];
        [self addGestureRecognizer:self.tapGesture];
    }
    if (self.tapGestureRecognizerBlock) {
        self.tapGestureRecognizerBlock = nil;
    }
    self.tapGestureRecognizerBlock = tapBlock;
}

#pragma mark - Events

/// 点击刷新按钮时处理事件
- (void)clickReloadBtn:(UIButton *)btn {
    SEL selector = NSSelectorFromString(@"xy_clickReloadBtn:");
    // 让btn所在的父控件去执行点击事件
    if ([self.superview respondsToSelector:selector]) {
        [self.superview performSelector:selector withObject:btn afterDelay:0.0];
    }
}

- (void)tapGestureOnSelf:(UITapGestureRecognizer *)tap {
    if (self.tapGestureRecognizerBlock) {
        self.tapGestureRecognizerBlock(tap);
    }
}

#pragma mark - Auto Layout
/// 移除所有约束
- (void)removeAllConstraints {
    [self removeConstraints:self.constraints];
    [_contentView removeConstraints:_contentView.constraints];
}

- (void)setupConstraints {
    
    // contentView 与 父视图 保持一致
    NSLayoutConstraint *contentViewX = [self equallyRelatedConstraintWithView:self.contentView attribute:NSLayoutAttributeCenterX];
    NSLayoutConstraint *contentViewY = [self equallyRelatedConstraintWithView:self.contentView attribute:NSLayoutAttributeCenterY];
    [self addConstraint:contentViewX];
    [self addConstraint:contentViewY];
    [self addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"H:|[contentView]|"
                                                                 options:0
                                                                 metrics:nil
                                                                   views:@{@"contentView": self.contentView}]];
    
    // 当verticalOffset(自定义的垂直偏移量)有值时，需要调整垂直偏移量的约束值
    if (self.contentOffsetY != 0.0 && self.constraints.count > 0) {
        contentViewY.constant = self.contentOffsetY;
    }
    
    // 若有customView 则 让其与contentView的约束相同
    if (_customView) {
        [self.contentView addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"H:|[customView]|"
                                                                                 options:0
                                                                                 metrics:nil
                                                                                   views:@{@"customView": _customView}]];
        [self.contentView addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"V:|[customView]|"
                                                                                 options:0
                                                                                 metrics:nil
                                                                                   views:@{@"customView": _customView}]];
    } else {
        
        // 无customView
        CGFloat width = CGRectGetWidth(self.frame) ?: CGRectGetWidth([UIScreen mainScreen].bounds);
        CGFloat horizontalSpace = roundf(width / 16.0); // 计算间距  四舍五入
        CGFloat verticalSpace = self.verticalSpace ?: 11.0; // 默认为11.0
        
        NSMutableArray<NSString *> *subviewsNames = [NSMutableArray arrayWithCapacity:0];
        NSMutableDictionary *views = [NSMutableDictionary dictionaryWithCapacity:0];
        NSDictionary *metrics = @{@"horizontalSpace": @(horizontalSpace)};
        
        // 设置backgroundImageView水平约束
        if (_imageView.superview) {
            [subviewsNames addObject:@"imageView"];
            views[[subviewsNames lastObject]] = _imageView;
            
            [self.contentView addConstraint:[self.contentView equallyRelatedConstraintWithView:_imageView attribute:NSLayoutAttributeCenterX]];
        }
        
        // 根据title是否可以显示，设置titleLable的水平约束
        if ([self canShowTitle]) {
            [subviewsNames addObject:@"titleLabel"];
            views[[subviewsNames lastObject]] = _titleLabel;
            
            [self.contentView addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"H:|-(horizontalSpace@750)-[titleLabel(>=0)]-(horizontalSpace@750)-|"
                                                                                     options:0
                                                                                     metrics:metrics
                                                                                       views:views]];
        } else {
            // 不显示就移除
            [_titleLabel removeFromSuperview];
            _titleLabel = nil;
        }
        
        // 根据是否可以显示detail, 设置detailLabel水平约束
        if ([self canShowDetail]) {
            [subviewsNames addObject:@"detailLabel"];
            views[[subviewsNames lastObject]] = _detailLabel;
            
            [self.contentView addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"|-(horizontalSpace@750)-[detailLabel(>=0)]-(horizontalSpace@750)-|"
                                                                                     options:0
                                                                                     metrics:metrics
                                                                                       views:views]];
        } else {
            // 不显示就移除
            [_detailLabel removeFromSuperview];
            _detailLabel = nil;
        }
        
        // 根据reloadButton是否能显示，设置其水平约束
        if ([self canShowReloadButton]) {
            [subviewsNames addObject:@"reloadButton"];
            views[[subviewsNames lastObject]] = _reloadButton;
            
            [self.contentView addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"|-(horizontalSpace@750)-[reloadButton(>=0)]-(horizontalSpace@750)-|"
                                                                                     options:0
                                                                                     metrics:metrics
                                                                                       views:views]];
        } else {
            // 不显示就移除
            [_reloadButton removeFromSuperview];
            _reloadButton = nil;
        }
        
        // 设置垂直约束
        NSMutableString *verticalFormat = [NSMutableString new];
        // 拼接字符串，添加每个控件垂直边缘之间的约束值, 默认为verticalSpace 11.0
        for (NSInteger i = 0; i < subviewsNames.count; ++i) {
            NSString *viewName = subviewsNames[i];
            // 拼接控件的属性名
            [verticalFormat appendFormat:@"[%@]", viewName];
            if (i < subviewsNames.count - 1) {
                // 拼接间距值
                [verticalFormat appendFormat:@"-(%.f@750)-", verticalSpace];
            }
        }
        
        // 向contentView分配垂直约束
        if (verticalFormat.length > 0) {
            [self.contentView addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:[NSString stringWithFormat:@"V:|%@|", verticalFormat]
                                                                                     options:0
                                                                                     metrics:metrics
                                                                                       views:views]];
        }
    }
    
}

// 控制器事件的响应
- (UIView *)hitTest:(CGPoint)point withEvent:(UIEvent *)event {
    
    UIView *hitView = [super hitTest:point withEvent:event];
    
    // 如果hitView是UIControl或其子类初始化的，就返回此hitView的实例
    if ([hitView isKindOfClass:[UIControl class]]) {
        return hitView;
    }
    
    // 如果hitView是contentView或customView, 就返回此实例
    if ([hitView isEqual:_contentView] || [hitView isEqual:_customView]) {
        return hitView;
    }
    
    return nil;
}

- (void)prepareForReuse {
    [_contentView.subviews makeObjectsPerformSelector:@selector(removeFromSuperview)];
    _titleLabel = nil;
    _detailLabel = nil;
    _imageView = nil;
    _customView = nil;
    _reloadButton = nil;
    
    [self removeAllConstraints];
}

@end

@implementation UIView (ConstraintBasedLayoutExtensions)

- (NSLayoutConstraint *)equallyRelatedConstraintWithView:(UIView *)view
                                               attribute:(NSLayoutAttribute)attribute {
    
    return [NSLayoutConstraint constraintWithItem:view
                                        attribute:attribute
                                        relatedBy:NSLayoutRelationEqual
                                           toItem:self attribute:attribute
                                       multiplier:1.0
                                         constant:0.0];
}

@end

@implementation WeakObjectContainer

- (instancetype)initWithWeakObject:(__weak id)weakObject {
    if (self = [super init]) {
        _weakObject = weakObject;
    }
    return self;
}

@end
