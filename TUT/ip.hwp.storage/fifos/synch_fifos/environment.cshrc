
# source /opt/modeltech-5.5d/modeltech.cshrc
# source /opt/modeltech-5.6b/modeltech.cshrc
 source /opt/modeltech-5.7a/modeltech.cshrc


# Synopsys-hommat pitaa sourcettaa vastaa Mentorin
# juttujen jalkeen, koska paskat Mentorin softat ei muuten
# toimi. Tulee maailman informatiivisin
# virheilmoitus "printenv: Undefined variable."

source /opt/synopsys/syn-2000.11/synopsys.cshrc






setenv USER_HOME $HOME


setenv CODEC_DATA_DIR /tmp/${USER}/Fifo_comparison
setenv CODEC_WORK_DIR ${PWD}

echo "###########"
echo Directory settings for fifo_comparison
echo   Data_dir = $CODEC_DATA_DIR
echo   Work_dir = $CODEC_WORK_DIR
echo "###########"





echo; echo " Environment is set"
