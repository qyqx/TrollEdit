#include "setting.h"
#include "ui_setting.h"

setting::setting(QWidget *parent) :
    QWidget(parent),
    ui(new Ui::setting)
{
    ui->setupUi(this);
}

setting::~setting()
{
    delete ui;
}

void setting::showSetting()
{
    this->setFixedSize(700,490);
    this->show();
}

void setting::on_pushButton_4_clicked()
{
    this->close();
}
