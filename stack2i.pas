UNIT stack2i;

INTERFACE {everything accessible to the outside}

TYPE

    NodePtr = ^Node;

    Node =
    RECORD
         X : INTEGER;
         Y : INTEGER;
         Next : NodePtr;
    END;

FUNCTION PUSH(Stack : NodePtr; NewNode: NodePtr) : NodePtr;
FUNCTION POP(Stack : NodePtr) : NodePtr; {returns the smaller stack, not the popped item}
FUNCTION MAKE_NODE(X : INTEGER; Y : INTEGER) : NodePtr;
FUNCTION CLEAR(Stack : NodePtr) : NodePtr;

IMPLEMENTATION

FUNCTION PUSH(Stack : NodePtr; NewNode: NodePtr) : NodePtr;
BEGIN         
     NewNode^.Next := Stack;
     PUSH := NewNode;
END;

FUNCTION POP(Stack : NodePtr) : NodePtr; {returns the smaller stack, not the popped item}
VAR
   SmallerStack : NodePtr;
BEGIN      
     SmallerStack := Stack^.Next; {make the second item the top of the stack}
     Dispose(Stack);
     POP := SmallerStack;
END;

FUNCTION CLEAR(Stack : NodePtr) : NodePtr;
BEGIN
     WHILE Stack <> NIL DO
     BEGIN
          Stack := POP(Stack);
     END;
     CLEAR := Stack;
END;


FUNCTION MAKE_NODE(X : INTEGER; Y : INTEGER) : NodePtr;
VAR
   NewNode : NodePtr;
BEGIN
     New(NewNode); {grab memory for the node and make NewNode point to it}
     NewNode^.X := X;
     NewNode^.Y := Y;
     NewNode^.Next := nil;
     MAKE_NODE := NewNode;
END;

END.