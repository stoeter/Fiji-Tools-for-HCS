var param1 = true
param2 =true
print("\\Clear");
print("param1 = global(var)", "param2 = non-global");

print("outside function",param1,param2)
test(param1, param2)
print("outside function",param1,param2)

print("test function var", "function has own variable names")
testfunctionvar(param1, param2)
print("outside function",param1,param2)
print("conclusion: global variable can be changed inside function if function uses its own variable name");

var param1 = true
param2 =true
print("test function without variable transfer", "only fixed value is given to function")
print("outside function",param1,param2)
test(false, false)
print("outside function",param1,param2)
print("conclusion: same as above. That means that function variable cannot be affected by globla variable, even if they have the same name, and global variable can be change only if function variable has a different name");

function test(param1,param2) {
	print("inside function",param1,param2)
	param1 = false
	param2 = false
	print("inside function",param1,param2)
}
function testfunctionvar(paramf1,paramf2) {
	print("inside function (functionvar)",param1,param2)
	param1 = false
	param2 = false
	print("inside function (functionvar)",param1,param2)
}