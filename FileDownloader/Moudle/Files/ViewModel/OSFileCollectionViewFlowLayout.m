//
//  OSFileCollectionViewFlowLayout.m
//  FileDownloader
//
//  Created by Swae on 2017/10/29.
//  Copyright © 2017年 Ossey. All rights reserved.
//

#import "OSFileCollectionViewFlowLayout.h"

typedef NS_ENUM(NSUInteger, OSLineDimensionType) {
    OSLineDimensionTypeSize,
    OSLineDimensionTypeMultiplier,
    OSLineDimensionTypeExtension
};

static OSLineDimensionType const OSLineDimensionTypeDefault = OSLineDimensionTypeSize;

static CGFloat const OSLineSizeDefault = 0;
static CGFloat const OSLineMutliplierDefault = 1;
static CGFloat const OSLineExtensionDefault = 0;

@interface OSFileCollectionViewFlowLayout ()

@property (nonatomic, copy, nullable) NSArray<NSValue *> * firstLineFrames;
@property (nonatomic, copy, nonnull, readonly) NSMutableDictionary<NSIndexPath *, __kindof UICollectionViewLayoutAttributes *> * itemAttributes;

/// 这个属性是用来记录lineDimension, 取决于itemSize
@property (nonatomic, assign) CGSize calculatedItemSize;

/// 记录collectionView的所有item个数
@property (nonatomic, assign) NSUInteger numberOfLines;

@property (nonatomic, assign) OSLineDimensionType lineDimensionType;

@end

@implementation OSFileCollectionViewFlowLayout

@synthesize scrollDirection = _scrollDirection;
@synthesize lineSize = _lineSize;
@synthesize lineMultiplier = _lineMultiplier;

-(instancetype)init
{
    self = [super init];
    if (self) {
        [self commonInit];
    }
    return self;
}

-(instancetype)initWithCoder:(nonnull NSCoder *)aDecoder
{
    self = [super initWithCoder:aDecoder];
    if (self) {
        [self commonInit];
    }
    return self;
}

-(void)commonInit
{
    [self setInitialDefaults];
    
    _firstLineFrames = nil;
    _itemAttributes = [NSMutableDictionary dictionary];
    _numberOfLines = 0;
}

-(void)setInitialDefaults
{
    // Default properties
    _scrollDirection = UICollectionViewScrollDirectionVertical;
    _lineDimensionType = OSLineDimensionTypeDefault;
    _lineSize = OSLineSizeDefault;
    _lineMultiplier = OSLineMutliplierDefault;
    _lineExtension = OSLineExtensionDefault;
    _lineItemCount = 4;
    _itemSpacing = 0;
    _lineSpacing = 0;
    _sectionsStartOnNewLine = NO;
}

-(void)invalidateLayout
{
    [super invalidateLayout];
    self.firstLineFrames = nil;
    [self.itemAttributes removeAllObjects];
    self.numberOfLines = 0;
    self.calculatedItemSize = CGSizeZero;
}

-(void)prepareLayout
{
    [super prepareLayout];
    
    self.numberOfLines = [self calculateNumberOfLines];
    
    self.calculatedItemSize = [self calculateItemSize];
    
    NSInteger const sectionCount = [self.collectionView numberOfSections];
    for (NSInteger section=0; section<sectionCount; section++) {
        
        NSInteger const itemCount = [self.collectionView numberOfItemsInSection:section];
        
        for (NSInteger item=0; item<itemCount; item++) {
            
            NSIndexPath *indexPath = [NSIndexPath indexPathForItem:item inSection:section];
            
            self.itemAttributes[indexPath] = [self calculateLayoutAttributesForItemAtIndexPath:indexPath];
        }
    }
}

-(CGSize)collectionViewContentSize
{
    CGSize size;
    
    switch (self.scrollDirection) {
        case UICollectionViewScrollDirectionHorizontal:
            size.width = self.numberOfLines * self.calculatedItemSize.width;
            // Add spacings
            if (self.numberOfLines > 0) {
                size.width += (self.numberOfLines - 1) * self.lineSpacing;
            }
            size.height = [self constrainedCollectionViewDimension];
            break;
            
        case UICollectionViewScrollDirectionVertical:
            size.width = [self constrainedCollectionViewDimension];
            size.height = self.numberOfLines * self.calculatedItemSize.height;
            // Add spacings
            if (self.numberOfLines > 0) {
                size.height += (self.numberOfLines - 1) * self.lineSpacing;
            }
            break;
    }
    
    return size;
}

-(nullable UICollectionViewLayoutAttributes *)layoutAttributesForItemAtIndexPath:(nonnull NSIndexPath *)indexPath
{
    UICollectionViewLayoutAttributes *layoutAttrs = self.itemAttributes[indexPath];
    
    if (!layoutAttrs) {
        layoutAttrs = [self calculateLayoutAttributesForItemAtIndexPath:indexPath];
        self.itemAttributes[indexPath] = layoutAttrs;
    }
    
    return layoutAttrs;
}

-(NSArray<__kindof UICollectionViewLayoutAttributes *> *)layoutAttributesForElementsInRect:(CGRect)rect
{
    NSMutableArray<__kindof UICollectionViewLayoutAttributes *> *layoutAttributes = [NSMutableArray arrayWithCapacity:[self.itemAttributes count]];
    
    [self.itemAttributes enumerateKeysAndObjectsUsingBlock:^(NSIndexPath *const indexPath, UICollectionViewLayoutAttributes *attr, BOOL *stop) {
        
        if (CGRectIntersectsRect(rect, attr.frame)) {
            [layoutAttributes addObject:attr];
        }
    }];
    
    return layoutAttributes;
}

-(BOOL)shouldInvalidateLayoutForBoundsChange:(CGRect)newBounds
{
    return !CGSizeEqualToSize(self.collectionView.bounds.size, newBounds.size);
}

#pragma mark - Lazily loaded properties

/// Precalculate the frames for the first line as they can be reused for every line
-(NSArray<NSValue *> *)firstLineFrames
{
    if (!_firstLineFrames) {
        
        CGFloat collectionConstrainedDimension = [self constrainedCollectionViewDimension];
        // Subtract the spacing between items on a line
        collectionConstrainedDimension -= (self.itemSpacing * (self.lineItemCount - 1));
        
        CGFloat constrainedItemDimension;
        switch (self.scrollDirection) {
            case UICollectionViewScrollDirectionVertical:
                constrainedItemDimension = self.calculatedItemSize.width;
                break;
                
            case UICollectionViewScrollDirectionHorizontal:
                constrainedItemDimension = self.calculatedItemSize.height;
                break;
        }
        
        // This value will always be less than the lineItemCount - this is the number of dirty pixels
        CGFloat remainingDimension = collectionConstrainedDimension - (constrainedItemDimension * self.lineItemCount);
        
        CGRect frame = CGRectZero;
        frame.size = self.calculatedItemSize;
        
        NSMutableArray<NSValue *> *frames = [NSMutableArray arrayWithCapacity:self.lineItemCount];
        
        for (NSUInteger i=0; i<self.lineItemCount; i++) {
            
            CGRect itemFrame = frame;
            
            // Add an extra pixel if we've got dirty pixels left
            if (remainingDimension-- > 0) {
                switch (self.scrollDirection) {
                    case UICollectionViewScrollDirectionVertical:
                        itemFrame.size.width++;
                        break;
                        
                    case UICollectionViewScrollDirectionHorizontal:
                        itemFrame.size.height++;
                        break;
                }
            }
            
            [frames addObject:[NSValue valueWithCGRect:itemFrame]];
            
            // Move to the next item
            switch (self.scrollDirection) {
                case UICollectionViewScrollDirectionVertical:
                    frame.origin.x = itemFrame.origin.x + itemFrame.size.width + self.itemSpacing;
                    break;
                    
                case UICollectionViewScrollDirectionHorizontal:
                    frame.origin.y = itemFrame.origin.y + itemFrame.size.height + self.itemSpacing;
                    break;
            }
        }
        
        _firstLineFrames = [frames copy];
    }
    
    return _firstLineFrames;
}

#pragma mark - Calculation methods

-(NSUInteger)calculateNumberOfLines
{
    NSInteger numberOfLines;
    if (self.sectionsStartOnNewLine) {
        
        numberOfLines = 0;
        
        NSInteger const sectionCount = [self.collectionView numberOfSections];
        for (NSInteger section=0; section<sectionCount; section++) {
            // If there are too many items to fill a line, allow it to over flow.
            numberOfLines += ceil(((CGFloat) [self.collectionView numberOfItemsInSection:section]) / self.lineItemCount);
        }
        
        // Best case: numberOfLines = number of sections with items
        // Worse case: numberOfLines = 2 * number of sections with items
        
    } else {
        
        NSUInteger n = 0;
        NSInteger const sectionCount = [self.collectionView numberOfSections];
        for (NSInteger section=0; section<sectionCount; section++) {
            n += [self.collectionView numberOfItemsInSection:section];
        }
        CGFloat numberOfItems = n;
        // We just need to work out the number of lines
        numberOfLines = ceil(numberOfItems / self.lineItemCount);
    }
    
    return numberOfLines;
}

-(CGSize)calculateItemSize
{
    CGFloat collectionConstrainedDimension = [self constrainedCollectionViewDimension];
    // 减去一行item之间的间距
    collectionConstrainedDimension -= (self.itemSpacing * (self.lineItemCount - 1));
    
    const CGFloat constrainedItemDimension = floor(collectionConstrainedDimension / self.lineItemCount);
    
    CGSize size = CGSizeZero;
    switch (self.scrollDirection) {
        case UICollectionViewScrollDirectionVertical:
            size.width = constrainedItemDimension;
            
            if ((self.lineSize == OSLineSizeDefault)
                && (self.lineMultiplier == OSLineMutliplierDefault)
                && (self.lineExtension == OSLineExtensionDefault)) {
                
                // item的宽高默认是相同的
                size.height = round(collectionConstrainedDimension / self.lineItemCount);
                
            } else {
                
                switch (self.lineDimensionType) {
                    case OSLineDimensionTypeSize:
                        size.height = self.lineSize;
                        break;
                        
                    case OSLineDimensionTypeMultiplier:
                        size.height = round(size.width * self.lineMultiplier);
                        break;
                        
                    case OSLineDimensionTypeExtension:
                        size.height = size.width + self.lineExtension;
                        break;
                }
            }
            break;
            
        case UICollectionViewScrollDirectionHorizontal:
            size.height = constrainedItemDimension;
            
            if ((self.lineSize == OSLineSizeDefault)
                && (self.lineMultiplier == OSLineMutliplierDefault)
                && (self.lineExtension == OSLineExtensionDefault)) {
                
                 // item的宽高默认是相同的
                size.width = round(collectionConstrainedDimension / self.lineItemCount);
                
            } else {
                
                switch (self.lineDimensionType) {
                    case OSLineDimensionTypeSize:
                        size.width = self.lineSize;
                        break;
                        
                    case OSLineDimensionTypeMultiplier:
                        size.width = round(size.height * self.lineMultiplier);
                        break;
                        
                    case OSLineDimensionTypeExtension:
                        size.width = size.height + self.lineExtension;
                        break;
                }
            }
            break;
    }
    
    return size;
}

-(nonnull UICollectionViewLayoutAttributes *)calculateLayoutAttributesForItemAtIndexPath:(nonnull NSIndexPath *)indexPath
{
    UICollectionViewLayoutAttributes *attrs = [[[self class] layoutAttributesClass] layoutAttributesForCellWithIndexPath:indexPath];
    
    CGRect frame;
    NSUInteger line;
    
    if (self.sectionsStartOnNewLine) {
        // As we start a section on a new line, this value does not need to account for previous sections
        frame = [self.firstLineFrames[indexPath.item % self.lineItemCount] CGRectValue];
        
        line = 0;
        for (NSInteger section=0; section<indexPath.section; section++) {
            // If there are too many items to fill a line, allow it to over flow.
            line += ceil(((CGFloat) [self.collectionView numberOfItemsInSection:section]) / self.lineItemCount);
        }
        // Add the line that this item is on in this section
        line += indexPath.item / self.lineItemCount;
        
    } else {
        
        // Need to calculate the number of items that have come before in previous sections
        NSUInteger numberOfItems = 0;
        for (NSInteger section=0; section<indexPath.section; section++) {
            // If there are too many items to fill a line, allow it to over flow.
            numberOfItems += [self.collectionView numberOfItemsInSection:section];
        }
        // And now calculate this items place
        numberOfItems += indexPath.item;
        
        // Get frame of this item - it'll be offset by the possible previous items on this line
        frame = [self.firstLineFrames[numberOfItems % self.lineItemCount] CGRectValue];
        
        // Now work out the line
        line = numberOfItems / self.lineItemCount;
    }
    
    // Work out the x/y offset depending on the scroll direction
    CGFloat spacingOffset = (line * self.lineSpacing);
    switch (self.scrollDirection) {
        case UICollectionViewScrollDirectionVertical:
            frame.origin.y += (line * self.calculatedItemSize.height) + spacingOffset;
            break;
            
        case UICollectionViewScrollDirectionHorizontal:
            frame.origin.x += (line * self.calculatedItemSize.width) + spacingOffset;
            break;
    }
    
    attrs.frame = frame;
    // Place below the scroll bar
    attrs.zIndex = -1;
    return attrs;
}

#pragma mark - Convenince sizing methods

-(CGFloat)constrainedCollectionViewDimension
{
    CGSize collectionViewInsetBoundsSize = UIEdgeInsetsInsetRect(self.collectionView.bounds, self.collectionView.contentInset).size;
    
    switch (self.scrollDirection) {
        case UICollectionViewScrollDirectionHorizontal:
            return collectionViewInsetBoundsSize.height;
            
        case UICollectionViewScrollDirectionVertical:
            return collectionViewInsetBoundsSize.width;
    }
}

#pragma mark - Detail setters that invalidate the layout

-(void)setScrollDirection:(UICollectionViewScrollDirection)scrollDirection
{
    NSAssert(scrollDirection == UICollectionViewScrollDirectionHorizontal || scrollDirection == UICollectionViewScrollDirectionVertical, @"Invalid scrollDirection: %ld", (long) scrollDirection);
    
    if (_scrollDirection != scrollDirection) {
        _scrollDirection = scrollDirection;
        
        [self invalidateLayout];
    }
}

-(void)setLineDimensionType:(OSLineDimensionType)lineDimensionType
{
    if (_lineDimensionType != lineDimensionType) {
        _lineDimensionType = lineDimensionType;
        
        [self invalidateLayout];
    }
}

-(void)setLineSize:(CGFloat)lineSize
{
    NSAssert(lineSize >= 0, @"Negative lineSize is meaningless");
    
    // Reset other line dimensions
    _lineMultiplier = OSLineMutliplierDefault;
    _lineExtension = OSLineExtensionDefault;
    self.lineDimensionType = OSLineDimensionTypeSize;
    
    if (_lineSize != lineSize) {
        _lineSize = lineSize;
        
        [self invalidateLayout];
    }
}

-(void)setLineMultiplier:(CGFloat)lineMultiplier
{
    NSAssert(lineMultiplier > 0, @"None positive lineMultiplier is meaningless");
    
    // Reset other line dimensions
    _lineSize = OSLineSizeDefault;
    _lineExtension = OSLineExtensionDefault;
    self.lineDimensionType = OSLineDimensionTypeMultiplier;
    
    if (_lineMultiplier != lineMultiplier) {
        _lineMultiplier = lineMultiplier;
        
        [self invalidateLayout];
    }
}

-(void)setLineExtension:(CGFloat)lineExtension
{
    NSAssert(lineExtension >= 0, @"Negative lineExtension is meaningless");
    
    // Reset other line dimensions
    _lineSize = OSLineSizeDefault;
    _lineMultiplier = OSLineMutliplierDefault;
    self.lineDimensionType = OSLineDimensionTypeExtension;
    
    if (_lineExtension != lineExtension) {
        _lineExtension = lineExtension;
        
        [self invalidateLayout];
    }
}

-(void)setLineItemCount:(NSUInteger)lineItemCount
{
    NSAssert(lineItemCount > 0, @"Zero line item count is meaningless");
    if (_lineItemCount != lineItemCount) {
        _lineItemCount = lineItemCount;
        
        [self invalidateLayout];
    }
}

-(void)setItemSpacing:(CGFloat)itemSpacing
{
    if (_itemSpacing != itemSpacing) {
        _itemSpacing = itemSpacing;
        
        [self invalidateLayout];
    }
}

-(void)setLineSpacing:(CGFloat)lineSpacing
{
    if (_lineSpacing != lineSpacing) {
        _lineSpacing = lineSpacing;
        
        [self invalidateLayout];
    }
}

-(void)setSectionsStartOnNewLine:(BOOL)sectionsStartOnNewLine
{
    if (_sectionsStartOnNewLine != sectionsStartOnNewLine) {
        _sectionsStartOnNewLine = sectionsStartOnNewLine;
        
        [self invalidateLayout];
    }
}

-(NSString *)description
{
    NSString *lineDimension;
    
    if ((self.lineSize == OSLineSizeDefault)
        && (self.lineMultiplier == OSLineMutliplierDefault)
        && (self.lineExtension == OSLineExtensionDefault)) {
        
        lineDimension = @"(Auto)";
        
    } else {
        
        switch (self.lineDimensionType) {
            case OSLineDimensionTypeSize:
                lineDimension = [NSString stringWithFormat:@"(Size, %.3lf)", self.lineSize];
                break;
            case OSLineDimensionTypeMultiplier:
                lineDimension = [NSString stringWithFormat:@"(Multiplier, %.3lf)", self.lineMultiplier];
                break;
            case OSLineDimensionTypeExtension:
                lineDimension = [NSString stringWithFormat:@"(Extension, %.3lf)", self.lineExtension];
                break;
        }
    }
    
    return [NSString stringWithFormat:@"<%@: %p; scrollDirection = %@; lineDimension = %@; lineItemCount = %llu; itemSpacing = %.3lf; lineSpacing = %.3lf; sectionsStartOnNewLine = %@>", NSStringFromClass([self class]), self, (self.scrollDirection == UICollectionViewScrollDirectionVertical ? @"Vertical" : @"Horizontal"), lineDimension, (unsigned long long) self.lineItemCount, self.itemSpacing, self.lineSpacing, (self.sectionsStartOnNewLine ? @"YES" : @"NO")];
}

@end

@interface OSFileCollectionViewFlowLayout (InspectableScrolling)

@property (nonatomic, assign) IBInspectable BOOL verticalScrolling;

@end

@implementation OSFileCollectionViewFlowLayout (InspectableScrolling)

-(BOOL)verticalScrolling
{
    return self.scrollDirection == UICollectionViewScrollDirectionVertical;
}

-(void)setVerticalScrolling:(BOOL)verticalScrolling
{
    self.scrollDirection = verticalScrolling ? UICollectionViewScrollDirectionVertical : UICollectionViewScrollDirectionHorizontal;
}

@end

