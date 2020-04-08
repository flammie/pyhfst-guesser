BEGIN {IFS="\t";}
NF == 3 {
    gsub(/:/, "\\:");
    printf("%s;%s:%s\n", $1, $3, $2);
}
