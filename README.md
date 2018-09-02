# NGPageLoadingSpeedDemo
iOS性能优化之页面加载速度
# iOS性能优化之页面加载速率

## 前言

之前搜罗了网上很多关于iOS性能优化方面的资料 ，本人和我的小伙伴们也用了一些时间针对自己的App进行了App的启动速率、页面的加载速率和 页面的帧率方面进行了优化，所以结合了理论和实践，把我们在实践中主要踩过的坑和需要注意的东西 ，总结了一下，希望可以帮到正在准备进行App的性能优化的你。今天主要讲一下App的页面加载速率的优化。
##目的
为了找到真正使我们的App缓慢的原因，我们使用Xcode或者一些第三方平台，进行数据测试；
## 一、页面加载速率的定义
页面加载速率：关于页面的加载速度的统计，我们是测试一个viewcontroller从viewdidload的第一行到viewdidappear的最后一行所用的时间。
## 二、页面加载速率的目标值
目标：页面加载速率最好完美的时间在0.3s左右
为了弄明白，到底是什么原因让我们的App，页面加载速度相对来说比较慢，我们对页面的UI进行优化，数据也进行了异步加载，我们hook数据一看，页面的加载速度果然有所减少，但是减少的值大概只有0.03s,很明显这个值不足以达到我们想要的效果，后来，通过写了一些测试demo，针对空白页面和有UI创建的页面进行各种对比后，似乎和我们页面加载过程中的push动画有很大的关系；下面所做的实验主要是为了验证这个问题，针对这个问题，我选取了我们工程的一个类，对有push进入到这个页面有过场动画和没有动画进行测试，以下数据是测试结果：
![](https://ws1.sinaimg.cn/large/007e49vogy1fuvhvyo7nzj30em0cutai.jpg)

通过这个实验，我们可以看出，不加动画的话，我们的页面加载的速度可以说是没有任何的卡顿，超级迅速，但是如果把过场动画给打开，单是动画的时间就是在0.5s左右，而s我们是希望用户在点击跳转页面的时候，目标是页面在0.3s左右呈现，这如果加动画，这个目标很难达到；不过通过查找相关资料，我们证实了我们可以把如果有过场动画的页面，去掉动画，而是通过我们自己去给用户添加一个过场动画，而这个时间是可以受到我们自己的控制，而不是傻傻的等动画结束后再加载页面内容。的这就是说，可以一边动画的时候，一边已经开始加载页面相关东西了，这样可以大大的优化页面加载时间。

## 三、优化前数据
到这里 ，你一定想问 ：我该如何hook数据的？？？
## 四、如何进行数据的收集
1.给UIViewController 创建一个分类 eg :UIViewController+Swizzle

2.代码如下
```
#import <UIKit/UIKit.h>
#import <objc/runtime.h>

@interface UIViewController (Swizzle)
@property(nonatomic,assign) CFAbsoluteTime viewLoadStartTime;

@end

```
```
#import "UIViewController+Swizzle.h"
#import <objc/runtime.h>

static char *viewLoadStartTimeKey = "viewLoadStartTimeKey";
@implementation UIViewController (Swizzle)
-(void)setViewLoadStartTime:(CFAbsoluteTime)viewLoadStartTime{
objc_setAssociatedObject(self, &viewLoadStartTimeKey, @(viewLoadStartTime), OBJC_ASSOCIATION_COPY);

}
-(CFAbsoluteTime)viewLoadStartTime{
return [objc_getAssociatedObject(self, &viewLoadStartTimeKey) doubleValue];
}
+ (void)load
{
static dispatch_once_t onceToken;
dispatch_once(&onceToken, ^{
SEL origSel = @selector(viewDidAppear:);
SEL swizSel = @selector(swiz_viewDidAppear:);
[UIViewController swizzleMethods:[self class] originalSelector:origSel swizzledSelector:swizSel];

SEL vcWillAppearSel=@selector(viewWillAppear:);
SEL swizWillAppearSel=@selector(swiz_viewWillAppear:);
[UIViewController swizzleMethods:[self class] originalSelector:vcWillAppearSel swizzledSelector:swizWillAppearSel];

SEL vcDidLoadSel=@selector(viewDidLoad);
SEL swizDidLoadSel=@selector(swiz_viewDidLoad);
[UIViewController swizzleMethods:[self class] originalSelector:vcDidLoadSel swizzledSelector:swizDidLoadSel];

SEL vcDidDisappearSel=@selector(viewDidDisappear:);
SEL swizDidDisappearSel=@selector(swiz_viewDidDisappear:);
[UIViewController swizzleMethods:[self class] originalSelector:vcDidDisappearSel swizzledSelector:swizDidDisappearSel];

SEL vcWillDisappearSel=@selector(viewWillDisappear:);
SEL swizWillDisappearSel=@selector(swiz_viewWillDisappear:);
[UIViewController swizzleMethods:[self class] originalSelector:vcWillDisappearSel swizzledSelector:swizWillDisappearSel];
});
}

+ (void)swizzleMethods:(Class)class originalSelector:(SEL)origSel swizzledSelector:(SEL)swizSel
{
Method origMethod = class_getInstanceMethod(class, origSel);
Method swizMethod = class_getInstanceMethod(class, swizSel);

//class_addMethod will fail if original method already exists
BOOL didAddMethod = class_addMethod(class, origSel, method_getImplementation(swizMethod), method_getTypeEncoding(swizMethod));
if (didAddMethod) {
class_replaceMethod(class, swizSel, method_getImplementation(origMethod), method_getTypeEncoding(origMethod));
} else {
//origMethod and swizMethod already exist
method_exchangeImplementations(origMethod, swizMethod);
}
}

- (void)swiz_viewDidAppear:(BOOL)animated
{
[self swiz_viewDidAppear:animated];
if (self.viewLoadStartTime) {
CFAbsoluteTime linkTime = (CACurrentMediaTime() - self.viewLoadStartTime);

NGLog(@" %f s--------------------ssssss   %@:速度：         %f s",self.viewLoadStartTime, self.class,linkTime  );
self.viewLoadStartTime = 0;
}
}

-(void)swiz_viewWillAppear:(BOOL)animated
{
[self swiz_viewWillAppear:animated];
}

-(void)swiz_viewDidDisappear:(BOOL)animated
{
[self swiz_viewDidDisappear:animated];
}

-(void)swiz_viewWillDisappear:(BOOL)animated
{
[self swiz_viewWillDisappear:animated];
}
-(void)swiz_viewDidLoad
{
self.viewLoadStartTime =CACurrentMediaTime();
NSLog(@" %@swiz_viewDidLoad startTime:%f",self.class, self.viewLoadStartTime );
[self swiz_viewDidLoad];
}

@end
```
##如何进行优化
1.方法：充分利用push 动画的时间 ，使页面在进入的时候，同事进行类似push 动画，这样可以充分减少页面的加载速度（不包括网络请求时间，网络的请求的时间我们这边不好控制）。

2.具体实现代码如下
重写 push方法

```
- (void)pushViewController:(UIViewController *)viewController animated:(BOOL)animated {

if (self.viewControllers.count > 0) {
viewController.hidesBottomBarWhenPushed = YES;
if (animated) {

CATransition *animation = [CATransition animation];
animation.duration = 0.4f;
animation.timingFunction = [CAMediaTimingFunction functionWithName:kCAMediaTimingFunctionEaseInEaseOut];
animation.type = kCATransitionPush;
animation.subtype = kCATransitionFromRight;
[self.navigationController.view.layer addAnimation:animation forKey:nil];
[self.view.layer addAnimation:animation forKey:nil];
[super pushViewController:viewController animated:NO];
return;
}
}
[super pushViewController:viewController animated:animated];
}

```


3.通过控制台 ，我们就可以看到页面的加载的速度了，主要的方法是swiz_viewDidLoad  和swiz_viewDidAppear 

## 五、优化后的结果

## 六、结果分析
我们可以看出，我们的页面的viewDidAppear是在过场动画结束后被调用的，而过场动画的持续时间是0.5秒左右。所以我们的页面平均在0.8秒左右的页面，如果要优化得更好，我们可以看有没有方法解决这个问题，如果能替换掉动画，让动画在进行的过程中 ，页面的加载也在异步的进行中，这样 我们就可以缩短页面的加载时间了；注：但这个加载对加载h5的页面不适用；



