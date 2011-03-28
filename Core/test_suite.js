var test_pass = 0;
var test_fail = 0;

function test_assert_true(string, test)
{
	if (test)
	{
		Print("test '" + string + "' passed!");
		test_pass = test_pass + 1;
	}
	else
	{
		Print("failed test: '" + string + "'");
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
		Print("Tests failed! " + test_fail + "/" + (test_pass + test_fail));
	}
	else
	{
		Print("All tests passed!");
	}
}

var patchA = new Patch();
var patchB = new Patch();
var patchCollection = new PatchCollection();

patchCollection.managePatch(patchA);
patchCollection.managePatch(patchB);

patchA.addInput("foo", 15);
patchA.addInput("blargh", 18);
patchA.addOutput("bar", function(){return this.getInput("foo") * 5.5;});
patchA.addOutput("bas", function(){return this.getInput("blargh") * 15.5;});

patchB.addInput("foo", 15);
patchB.addInput("blargh", 18);
patchB.addOutput("bar", function(){return this.getInput("foo") * 5.5;});
patchB.addOutput("bas", function(){return this.getInput("blargh") * 15.5;});

////////////////////////////

test_assert_equal("patchA output 'bar' set", patchA.getOutput("bar"), 82.5);
test_assert_equal("patchA output 'bas' set", patchA.getOutput("bas"), 279.0);

patchA.connect("foo", patchB, "bar");
test_assert_equal("patchB output 'bar' updated", patchA.getOutput("bar"), 453.75);
test_assert_equal("patchB output 'bas' unchanged", patchA.getOutput("bas"), 279.0);

patchCollection.saveToFile("test1.xml");
test_assert_true("Patch Collection Save to File", true);

patchA.disconnectInput("foo");
test_assert_equal("bar reset", patchA.getOutput("bar"), 82.5);
test_assert_equal("bas unchanged", patchA.getOutput("bas"), 279.0);


patchCollection.saveToFile("test2.xml");

var patchCollection2 = new PatchCollection("test1.xml");
patchCollection2.saveToFile("test3.xml");
test_assert_true("Patch Collection Load from File", true);

var iSetA = new IndexSet(100);
var iSetB = new IndexSet(75, 125);
var iSetC = new IndexSet();
var iSetD = new IndexSet();

var testIndices = new Array();
iSetC.intersect(iSetA, iSetB);
iSetC.filter(function (id){return ((id%2)==0)}, null, iSetD);
iSetD.forAll(function (id){testIndices[id] = true;}, this);

var index_count = 0;
var index_value = 0;
for (id in testIndices)
{
	test_assert_true("Index " + id + " in range", 76 <= id && id <= 98);
	if (id == index_value * 2 + 76)
		index_value++
	else
		Print("Index " + id + " failed!");
	index_count++;
}
test_assert_true("Index count: " + index_count, index_count == 12);
test_assert_true("Index value: " + index_value, index_value == 12);

tests_complete();

