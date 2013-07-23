divvyapp
========
Hey guys I loaded up some issues...

To do:
1) Implement smooth transitions from the mapview to the instruction view that follow a swipe on the "present list" button

Bugs: 

1) When pressing "present list" sometimes the app crashes, the error is that there is an attempt to index an array beyond 0.
   Theories for why this occurs:
     a) There are no instructions, it segues and attempts to read from an empty array.
     b) Sometimes though it seems there are instructions... it could be that somehow they don't load into the variable
     c) We are somehow trying to navigate before the variables are stored
     d) More likely is that the app receives multiple asynchronous messages for each leg of the journey... they override
        each other and cause the app to crash.  Probably we should test for this and recall the methods to make sure the
        trip loads correctly.  This is, of course, a little messy, but I am not sure how else to solve it...
        The thing that goes against this error though is that the polylines still route correctly when the error occurs

Clearly still more exploration needs to happen here
     
     


