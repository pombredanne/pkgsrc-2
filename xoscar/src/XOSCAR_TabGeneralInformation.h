#ifndef XOSCAR_TABGENERALINFORMATION_H
#define XOSCAR_TABGENERALINFORMATION_H

#include "XOSCAR_TabWidgetInterface.h"
#include "ui_xoscar_generalinformation.h"
#include "CommandExecutionThread.h"

using namespace Ui;

namespace xoscar {

class XOSCAR_TabGeneralInformation : public QWidget, public GeneralInformationForm, public XOSCAR_TabWidgetInterface
{
Q_OBJECT

public:
    XOSCAR_TabGeneralInformation(QWidget* parent=0);
    ~XOSCAR_TabGeneralInformation();

public slots:
    void partitionName_textEdited_handler(const QString&);
    void partitionDistro_currentIndexChanged_handler(int);
	void partitionNodes_valueChanged_handler(int);
	void add_partition_handler();
	void save_cluster_info_handler();
	void refresh_list_partitions();
    void refresh_partition_info();
     int handle_thread_result (int command_id, const QString result);
    void handle_oscar_config_result(QString list_distros);
	bool save();
	bool undo();

signals:
    void widgetContentsModified(QWidget* widget);
	void widgetContentsSaved(QWidget* widget);

private:
   CommandExecutionThread command_thread;

   bool loading;
};

}

#endif // XOSCAR_TABGENERALINFORMATION_H
