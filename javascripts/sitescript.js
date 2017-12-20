// use strict mode
"use strict";

$(document).ready( function(){
    var platform;

// A cookie is used to make sure each page uses the same setting.  Whenever the setting changes,
// the cookie is updated. The setting can change through the commandline, radiobutton choice, 
// or dropdown list choice. 


// Get the cookie.  If no cookie, default to CIG and set the cookie.
// XXX change the -sitename for each new website so the cookies don't overlap sites!
// there are 7 occurrences of Cookies.get or .set in this script - change them all.
    if (Cookies.get('platform-los')) {
        platform = (Cookies.get('platform-los'));
    } else {
        platform = 'cig';
        Cookies.set('platform-los', platform );       
    }
    if (Cookies.get('platform-los') != platform) {
        // if cookies don't work, show the dropdown instead on pages which need it.
        $('.choose').css("display","inline");
    }

// if commandline has a value, set the cookie 
// note the name of the var is ignored, only the value specified after the "=" is important
if ( window.location.search.split('=')[1]) {
    platform = window.location.search.split('=')[1];
    console.log (" Argument is " + platform )
    // make sure the argument is a valid value  
    if ($.inArray( platform, [ "cig","onp", "py" ] ) > -1 ) {
        Cookies.set('platform-los', platform ); 
    }
}
 
    // initialize page - sets both radiobutton and dropdown whichever the page uses (or both!)
    setRb ( platform )
    setDl ( platform )
    changeVis( platform )

    //changing the dropdown changes visibility, cookie, and rb
    $('.ch-platform').change(function () {
        var newval = $('.ch-platform option:selected').val();
        changeVis ( newval );
        Cookies.set ('platform-los', newval )
        setRb ( newval );
    });

    //changing the radiobutton changes visibility, cookie, and dl
    $('input[type=radio][name=optradio]').change(function(){
        changeVis( this.value );
        Cookies.set('platform-los', this.value );
        setDl ( this.value );
    });

// change visibility of all the appropriate divs on the page 
// note that both cig and onp show the ".sql" div 
    function changeVis (value) {
        switch (value) {
            case 'cig':
                $('.cig').show();
                $('.sql').show();
                $('.onp').hide();    
            break;

            case 'onp':
                $('.cig').hide();
                $('.sql').show();
                $('.onp').show();
            break;

            case 'py':
                $('.cig').hide();
                $('.sql').hide();
                $('.onp').hide();
            break;
        }
    };

// set the rb
    function setRb (value) {
        switch (value) {
            case 'cig':
                $("input[name=optradio][value=cig]").prop("checked",true);
            break;

            case 'onp':
                $("input[name=optradio][value=onp]").prop("checked",true);
            break;

            case 'py':
                $("input[name=optradio][value=py]").prop("checked",true);
            break;
        }
    };

// set the dl
    function setDl ( value ) {
        $(".ch-platform").val( value ).change();
        console.log ("set to " + value )
    };


})

