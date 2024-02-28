# prometheus 查询时，increase之类的函数，对于整数数值计算，为什么会出现小数？
因为他会对边界做数据推断。
https://promlabs.com/blog/2021/01/29/how-exactly-does-promql-calculate-rates/
