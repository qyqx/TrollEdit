#ifndef BLOCK_H
#define BLOCK_H

#include <QGraphicsRectItem>
#include <QtGui>

class TreeElement;
class DocumentScene;
class HideBlockButton;
class TextItem;

class Block : public QObject, public QGraphicsRectItem
{
    Q_OBJECT

public:
    Block(TreeElement *element, Block *parentBlock = 0, QGraphicsScene *parentScene = 0);
    ~Block();

    enum { Type = UserType + 1 };
    int id;

    // overriden methods to provide AST consistency
    void setParentItem (QGraphicsItem *parent);
    void stackBefore (const QGraphicsItem *sibling);

    void setFolded(bool folded);
    bool isFolded() const;
    bool isTextBlock() const;
    Block *getNextSibling() const;
    Block *getPreviousSibling() const;
    int numberOfLines() const;
    int getLineAfter() const;

    DocumentScene *docScene() const;
    Block *parentBlock() const;
    QList<Block*> childBlocks() const;
    TextItem *textItem() const;

    QPainterPath shape() const;
    int type() const;
    QRectF boundingRect() const;
    void paint(QPainter *painter, const QStyleOptionGraphicsItem *option, QWidget *widget);
    QList<Block*> blocklist_cast(QList<QGraphicsItem*> list) const;

    void setChanged();

signals:
    void lostFocus(Block *block);

public slots:
    void textFocusChanged(QFocusEvent* event);
    void textChanged();
    void addNewLineAfterThis();
    void moveCursorLR(int key);
    void moveCursorUD(int key);

protected:
    int getLineYPos(int line) const;

    int updateLayout(int lineNo);
    void updateChildrenPosAfter(Block *child, int lineNo);
    void updateChildrenPosInLine(int lineNo);
    Block* findNextChildAt(QPointF pos) const;
    QLineF getInsertLineAt(const Block* nextBlock) const;

    void focusOutEvent(QFocusEvent *event);
    QVariant itemChange(GraphicsItemChange change, const QVariant & value);

    void mousePressEvent(QGraphicsSceneMouseEvent *event);
    void mouseMoveEvent(QGraphicsSceneMouseEvent *event);
    void mouseReleaseEvent(QGraphicsSceneMouseEvent *event);

    void hoverEnterEvent(QGraphicsSceneHoverEvent *event);
    void hoverLeaveEvent(QGraphicsSceneHoverEvent *event);
    void hoverMoveEvent(QGraphicsSceneHoverEvent *event);

    void contextMenuEvent(QGraphicsSceneContextMenuEvent *event);
    void dragEnterEvent(QGraphicsSceneDragDropEvent *event);
    void dragLeaveEvent(QGraphicsSceneDragDropEvent *event);
    void dragMoveEvent(QGraphicsSceneDragDropEvent *event);


private:
    static const int OFFS = 10;

    bool folded;    // true when block is folded
    bool pressed;   // true while mouse is pressed
    bool changed;   // changed after last updateLayout() call

    TreeElement *element;
    TextItem *myTextItem;
    int line;       // index of line in multiline parent

    // graphic elements
    HideBlockButton *hideButton;

    void createControls();//todo
    void childAdded(Block *newChild);
    void childRemoved(Block *oldChild);

    Block *futureParent;
    Block *futureSibling;   // used for block insertion
};

#endif // BLOCK_H
