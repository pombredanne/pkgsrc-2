/*
 *  Copyright (c) 2007-2008 Oak Ridge National Laboratory, 
 *                          Geoffroy Vallee <valleegr@ornl.gov>
 *                          All rights reserved
 *  This file is part of the xoscar software, part of the OSCAR software.
 *  For license information, see the COPYING file in the top level directory
 *  of the OSCAR source.
 */

/**
 * @file XOSCAR_TabWidgetInterface.h
 * @brief Defines the interface XOSCAR_TabWidgetInterface for the tab widgets
 * that need to support tracking of changes.
 * @author Robert Babilon
 */

#ifndef XOSCAR_TABWIDGETINTERFACE_H
#define XOSCAR_TABWIDGETINTERFACE_H
#include <QWidget>

namespace xoscar { 

class XOSCAR_TabWidgetInterface
{
public:
    enum SaveResult { Saving, Undoing, NoChange, SaveFailed, UserCanceled };

    XOSCAR_TabWidgetInterface();
    ~XOSCAR_TabWidgetInterface();

    virtual SaveResult save() = 0;
    virtual SaveResult undo() = 0;

    virtual bool isModified() const { return modified; }

signals:
    virtual void widgetContentsModified(QWidget* widget)=0;

protected:
    virtual void setModified(const bool mod) { modified = mod; }
    bool modified;
};

} // namespace xoscar

#endif // XOSCAR_TABWIDGETINTERFACE_H
