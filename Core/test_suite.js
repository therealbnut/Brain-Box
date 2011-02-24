var test_pass = 0;
var test_fail = 0;

function test_assert_true(string, test)
{
	if (test)
	{
		test_pass = test_pass + 1;
	}
	else
	{
		print("failed test: '" + string + "'");
		test_fail = test_fail + 1;
	}
}
function test_assert_equal(string, testA, testB)
{
	return test_assert_true(string, testA == testB);
}
function tests_complete()
{
	if (test_fail != 0)
	{
		print("Tests failed! " + test_fail + "/" + (test_pass + test_fail));
	}
	else
	{
		print("All tests passed!");
	}
}

var patchA = new Patch();
var patchB = new Patch();

patchA.addInput("foo", 15);
patchA.addInput("blargh", 18);
patchA.addOutput("bar", function(){return this.getInput("foo") * 5.5;});
patchA.addOutput("bas", function(){return this.getInput("blargh") * 15.5;});

patchB.addInput("foo", 15);
patchB.addInput("blargh", 18);
patchB.addOutput("bar", function(){return this.getInput("foo") * 5.5;});
patchB.addOutput("bas", function(){return this.getInput("blargh") * 15.5;});

////////////////////////////

test_assert_equal("bar set", patchA.getOutput("bar"), 82.5);
test_assert_equal("bas set", patchA.getOutput("bas"), 279.0);

patchA.connect("foo", patchB, "bar");
test_assert_equal("bar updated", patchA.getOutput("bar"), 453.75);
test_assert_equal("bas unchanged", patchA.getOutput("bas"), 279.0);

patchA.disconnectInput("foo");
test_assert_equal("bar reset", patchA.getOutput("bar"), 82.5);
test_assert_equal("bas unchanged", patchA.getOutput("bas"), 279.0);

tests_complete();
