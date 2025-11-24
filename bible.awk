#! /bin/awk -f
BEGIN { \
	FS=":" 
	FIRSTCH=0
	FIRSTVS=0 
	CURRCH=0
}
{
	if ( FIRSTCH == 0 )
		FIRSTCH=$1
		FIRSTVS=$2

	if ( CURRCH != $1 )			
		print "\n" "\n" $1 "\n" "----------------------------------------------" "\n"
		CURRCH=$1

	PENULT1=$LAST1
	PENULT2=$LAST2
	LAST1=$1
	LAST2=$2		
	print $2 $3 $4 $5
}
END { \

}
