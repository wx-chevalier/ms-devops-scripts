#!/bin/bash

getType(){
    echo "1 : Download and install to current folder"
    echo "2 : Download only"
    echo "q : Quit"
    while(true) ;do
        echo -n "Enter a value:"
        read choice < /dev/tty
        if [ "$choice" = "q" ];then exit 0;fi
        if [ "$choice" -gt "0" 2>/dev/null ] && [ "$choice" -lt "4" 2>/dev/null ]; then
            return $choice;
        else
            echo "$choice is not valid option!"
        fi
    done 
}

do_download(){
    fetch_dir=$1;
    if [ ! -d $fetch_dir ]; then
        echo "$fetch_dir is not vaild!"
        exit 1;
    fi
    cd $fetch_dir
    test_exists $fetch_dir
    set +e
    type "git" >/dev/null 2>/dev/null
    has_git=$?
    set -e
    if [ "$has_git" -eq 0 ];then
        echo "fetching source from github"
        do_fetch  $fetch_dir;
    else
        set +e
        type "svn" >/dev/null 2>/dev/null
        has_svn=$?
        set -e
        if [ "$has_svn" -eq 0 ];then
            echo "fetching source from github using svn"
            do_fetch $fetch_dir svn;
        else
            echo "can't locate svn ,using archive mode."
            do_download_archive $fetch_dir;
        fi
    fi
    echo "awesome-scripts is downloaded to $fetch_dir/awesome-scripts"
}

do_download_archive(){
    wget https://codeload.github.com/superhj1987/awesome-scripts/zip/master -O awesome-scripts.zip
    unzip awesome-scripts.zip
    rm -rf awesome-scripts.zip
    mv awesome-scripts-master awesome-scripts
    cd awesome-scripts
}

do_fetch(){
    fetch_dir=$1;
    if [ ! -d $fetch_dir ]; then
        echo "$fetch_dir is not vaild!"
        exit 1;
    fi
    cd $fetch_dir ;
    test_exists awesome-scripts;
    if [[ $# < 2 || "$2" = "git" ]]; then
        git clone https://github.com/superhj1987/awesome-scripts.git awesome-scripts --depth=1
    else
        svn checkout https://github.com/superhj1987/awesome-scripts/trunk awesome-scripts
    fi
    cd awesome-scripts 
    return 0 
}

test_exists(){
    if [ -e awesome-scripts ]; then
        echo "$1/awesome-scripts already exist!"
        while(true);do
            echo -n "(q)uit or (r)eplace?"
            read choice < /dev/tty
            if [ "$choice" = "q" ];then
                exit 0;
            elif [ "$choice" = "r" ];then
                rm -fr $1/awesome-scripts
                break;
            else
                echo "$choice is not valid!"
            fi  
        done
    fi
}

do_install(){
    echo '***install need sudo,please enter password***'
    sudo make install
    echo 'awesome-scripts was installed to /usr/local/bin,have fun.'
}

main(){
    getType
    type=$?
    set -e
    case "$type" in 
        ("1")
            echo "Launching awesome-scripts installer..."
            do_download `pwd`
            do_install
            ;;
        ("2")
            echo "Start downloading awesome-scripts ..."
            do_download `pwd`
            ;;
    esac
}

main "$@"