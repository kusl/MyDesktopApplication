Instructions: 
I want to learn Avalonia UI to write high performance cross platform free of cost. 
I want to use the latest and greatest technology. 
I want this to serve as a sample as well as a starting point for native applications. 
It should be easy to use the latest dotnet technology 
such as slnx files, props files, and so on. 
Where possible, we should use long term sustainable technology such as sqlite and postgresql. 
We should avoid any nuget package that requires payment of money, free of cost for non-commercial software is not enough. 
We ourselves should not charge any money, ever. 
We should have extensive logging, metrics, etc using open telemetry. 
Application should be built from the ground up to be testable.
All tests including Unit tests, integration tests should be automated and be performant so we can run them after every change. 
The whole thing should fit in a single git repository. 

Do not generate multiple `slnx` for desktop and android etc no matter how tempting it feels. 
do not generate `build-desktop.sh` and `build-android.sh` scripts to silo the different teams. 
do not attempt to silo different teams at all. 
this is a cross functional team and everyone can work with all parts of the code. 
especially with claude opus 4.5 (or later) 
there is no excuse to silo people like this 
we should fix things properly, not put bandaid on problems by separating desktop and android teams 
if the build is slow, 
everyone should suffer 
not because we are masochists 
but because we want everyone to know when stuff is broken 
so it gets fixed as quickly as possible. 
