#!/bin/bash
######################################################################
#  File				: dailybiblereading.sh                           #
#  Input Values		: None                                           # 
#  Purpose			: Get Bible text for this day's Daily Reading    #
#                     using Diatheke, reformat it and open in text   #
#                     editor for note-taking and journaling.         #
######################################################################

# ====================================================================
# Testing -- comment out lines below when script is complete
# ====================================================================
DOY=`date +%j`
DOM=`date +%e`
MONTH=`date +%b`
YEAR=`date +%Y`
DESTDIR="/home/scott/backup/Discipleship/DailyBibleReading/"
DESTFILE="${MONTH}${DOM}DailyBibleReading${YEAR}.rst.txt"


# = End Testing ======================================================

# ====================================================================
# Independent variables
# ====================================================================

#ALTDATE=
#DOY=

# ====================================================================
# Dependent Variables
# Nothing to change below this line
# ====================================================================

# ====================================================================
# Code Below
# ====================================================================

# Get the day of the year for today's date

# Get the Bible Reading Passages for this day of the year

READING1=`grep ^$DOY ~/backup/Discipleship/DailyBibleReading/BRP_fullyear.csv | cut -d "," -f 2`
READING2=`grep ^$DOY ~/backup/Discipleship/DailyBibleReading/BRP_fullyear.csv | cut -d "," -f 3`
READING3=`grep ^$DOY ~/backup/Discipleship/DailyBibleReading/BRP_fullyear.csv | cut -d "," -f 4`

# Output to File and Open for Editing

#echo "diatheke -b NET -k $*"

cat > ${DESTDIR}${DESTFILE} <<'EOF'
.. Sequence of section adornments:
.. ==--
.. ==--==--__++~~^^

.. Files for use with the ``.. include:: ...`` directive are located at /home/scott/backup/rst.includes/

=========================================================================
Daily Bible Reading -- Text, Notes, Journaling
=========================================================================
-------------------------------------------------------------------------
EOF
echo "${MONTH} ${DOM}" >> ${DESTDIR}${DESTFILE}
echo "-------------------------------------------------------------------------" >> ${DESTDIR}${DESTFILE}

cat >> ${DESTDIR}${DESTFILE} <<'EOF'

Reading 1
===============

EOF

diatheke -b NET -k $READING1 |grep -v "(NET)" | awk -f /home/scott/backup/scripts/bible.awk >> ${DESTDIR}${DESTFILE}

cat >> ${DESTDIR}${DESTFILE} <<'EOF'

Reading 2
===============

EOF


diatheke -b NET -k $READING2 |grep -v "(NET)"  | awk -f /home/scott/backup/scripts/bible.awk >> ${DESTDIR}${DESTFILE}

cat >> ${DESTDIR}${DESTFILE} <<'EOF'

Reading 3
===============

EOF


diatheke -b NET -k $READING3 |grep -v "(NET)"  | awk -f /home/scott/backup/scripts/bible.awk >> ${DESTDIR}${DESTFILE}

gedit ${DESTDIR}${DESTFILE}


# cat > /tmp/file <<'EOF'
#   file stuff here
# EOF
