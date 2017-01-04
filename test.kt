package a.b


import c.d.E
import e.f.G
import e.d.G
import ayy.lmao.*
import testing.a.v.Myclass
import wild.*
import test.aaa.Class

class D(arg: E) : C(arg.B) {

}

class C(arg: B) {

}

class B : A(Foo) {

}

class A : B {
 fun test() = "ayy"
 fun moo() {
    object : Nested() {
      fun lmao() {
        {HEE HEE. RANDOM BRACKETS}
        // } Bracket in a comment
        object : test.ayy.Lmao() {
          // { Another comment
        }
      }

      /**
       * Ayy lmao this is cool
       *
       * This is pretty detailed. Time to test the KDoc syntax. All of the tags are below.
       * Now we go for the more advanced stuff, like linking [Name][link]
       * Link to a known type: [String]
       *
       * # Markdown Syntax works too
       * ## Like headers
       *
       * > Block quotes
       * > Work as well
       *
       * This is pretty **bold**
       * This is pretty *tilted*
       * This has inline `code`
       *
       *  Code Block
       *  Test
       *
       * @param function This parameter is a Lambda
       * @return Unit
       * @constructor This is the constructor
       * @receiver This is an extention function for ________
       * @property Test This proprety is a string
       * @throws SomeError This error can be thrown sometimes
       * @exception SomeException See above
       * @sample SomeSample See here how this can be used
       * @see Class
       * @author Adrian Vovk
       * @since v1.2.3
       * @suppress
       * @invalid This tag is invalid
       */
      fun ayy(arg: Test, arg1: (arg: String) -> String, arg3: Int) : String {
        // Stuff
        {a: Test -> return a}

        var arg: (arg: List<String>) -> String = {test -> Foo()}
        call()
      }
    }
 }
}
