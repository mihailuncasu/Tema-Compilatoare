%{
	#include <stdio.h>
  #include <string.h>

	int yylex();
	int yyerror(const char *errorMessage);
	extern FILE* yyin;

  int isCorrect = 1;
	char errorMessage[50];

	// M: Tabela de simboli;
	class TVAR
	{
		char* name;
	  int value;
	  TVAR* next;
	  
	  public:
	    static TVAR* head;
	    static TVAR* tail;

			TVAR();
	    TVAR(char* n, int v);
	  	int exists(char* n);
      void add(char* n, int v = -100);
  		int getValue(char* n);
	    void setValue(char* n, int v);
	};

	TVAR* TVAR::head;
	TVAR* TVAR::tail;

	TVAR::TVAR()
	{
	  TVAR::head = NULL;
	  TVAR::tail = NULL;
	}

	TVAR::TVAR(char* n, int v)
	{
		this->name = new char[strlen(n)+1];
		strcpy(this->name,n);
		this->value = v;
		this->next = NULL;
	}

	int TVAR::exists(char* n)
	{
	  TVAR* tmp = TVAR::head;
	  while(tmp != NULL)
	  {
	    if(strcmp(tmp->name,n) == 0)
		{
			return 1;
		}
      	tmp = tmp->next;
	  }
	  return 0;
	}

  void TVAR::add(char* n, int v)
	{
		TVAR* element = new TVAR(n, v);
	 	if(head == NULL)
	 	{
	    TVAR::head = TVAR::tail = element;
	 	}
	 	else
	 	{
		  TVAR::tail->next = element;
	    TVAR::tail = element;
	  }
	}

  int TVAR::getValue(char* n)
	{
	  TVAR* tmp = TVAR::head;
	  while(tmp != NULL)
	  {
	    if(strcmp(tmp->name,n) == 0)
			{
				return tmp->value;
			}
	    tmp = tmp->next;
	  }
	  return -1;
	}

  void TVAR::setValue(char* n, int v)
  {
    TVAR* tmp = TVAR::head;
    while(tmp != NULL)
    {
      if(strcmp(tmp->name,n) == 0)
      {
				tmp->value = v;
	    }
	  	tmp = tmp->next;
	  }
	}

	TVAR* ts = NULL;

	bool isReadWrite = false;
%}

%union { char* str; int val; }


%token TOK_PROGRAM TOK_VAR TOK_BEGIN TOK_END TOK_INTEGER
%token TOK_DIV TOK_READ TOK_WRITE TOK_FOR TOK_DO TOK_TO
%token TOK_LEFT TOK_RIGHT TOK_ATTRIBUTION
%token TOK_PLUS TOK_MINUS TOK_MULTIPLY TOK_ERROR

%token 	<val> TOK_INT
%type 	<val> Expression Termen Factor

%token 	<str> TOK_ID
%type 	<str> IdList
%type 	<str> IdListReadWrite

%start Program 

%left TOK_PLUS TOK_MINUS
%left TOK_MULTIPLY TOK_DIV

%locations

%%

Program: 							TOK_PROGRAM ProgramName TOK_VAR DeclarationList TOK_BEGIN StatementList TOK_END						
									{ 
										isCorrect = 1; 
									}	
									;

ProgramName:						TOK_ID
									;

DeclarationList:					Declaration
							  		| 
									DeclarationList ';' Declaration
									;

Declaration:						IdList ':' Type
									{
										
									}
									;

Type:								TOK_INTEGER
									;

IdList:								TOK_ID
									{
										if (ts != NULL)
										{
											if (ts->exists($1) && !isReadWrite) 
											{
												// M: If the variable already exists;
												sprintf(errorMessage, "%d:%d Semantic error: Multiple declarations for the same variable %s!", @1.first_line, @1.first_column, $1);
												yyerror(errorMessage);
												YYERROR;
											}
											else
											{
												isReadWrite = false;
												ts->add($1);
											}
										}
										else 
										{
											ts = new TVAR();
											ts->add($1);
										}
									}
			 						| 
									IdList ',' TOK_ID 
									{
										if (ts != NULL)
										{
											if (ts->exists($3)) 
											{
												// M: If the variable already exists;
												sprintf(errorMessage, "%d:%d Semantic error: Multiple declarations for the same variable %s!", @3.first_line, @3.first_column, $3);
												yyerror(errorMessage);
												YYERROR;
											}
											else
											{
												ts->add($3);
											}
										}
										else
										{
											ts = new TVAR();
											ts->add($3);
										}
									}
									;

IdListReadWrite:					TOK_LEFT TOK_ID TOK_RIGHT
									{
										if (ts != NULL)
										{
											if (!ts->exists($2)) 
											{
												// M: If the variable already exists;
												sprintf(errorMessage, "%d:%d Semantic error: No declaration for variable %s!", @1.first_line, @1.first_column, $2);
												yyerror(errorMessage);
												YYERROR;
											}
											else
											{
												ts->setValue($2,100);
											}
										}
										else 
										{
											// M: If the variable already exists;
											sprintf(errorMessage, "%d:%d Semantic error: No declaration for variable %s!", @1.first_line, @1.first_column, $2);
											yyerror(errorMessage);
											YYERROR;
										}
									}
									;

StatementList:						Statement
									| 
									StatementList ';' Statement
									;

Statement:							Assign
									|
									Read 
									|
									Write 
									|
									For 
									;

Assign:								TOK_ID TOK_ATTRIBUTION Expression
									{
										if (ts != NULL)
										{
											if (!ts->exists($1)) 
											{
												// M: If the variable dosen't exist;
												sprintf(errorMessage, "%d:%d Semantic error: No declaration for variable %s!", @1.first_line, @1.first_column, $1);
												yyerror(errorMessage);
												YYERROR;
											}
											else 
											{
												ts->setValue($1,$3);
											}
										}
										else 
										{
											// M: If the variable dosen't exist;
											sprintf(errorMessage, "%d:%d Semantic error: No declaration for variable %s!", @1.first_line, @1.first_column, $1);
											yyerror(errorMessage);
											YYERROR;
										}
									}
									;

Expression:							Termen
									|
									Expression TOK_PLUS Termen
									|
									Expression TOK_MINUS Termen
									;

Termen: 							Factor
									|
									Termen TOK_MULTIPLY Factor
									|
									Termen TOK_DIV Factor
									{
										if ($3 == 0)
										{
											// M: Can't divide to 0;
											sprintf(errorMessage, "%d:%d Semantic error: Second termen value is 0!", @1.first_line, @1.first_column);
											yyerror(errorMessage);
											YYERROR;
										}
									}
									;

Factor:								TOK_ID
									{
										if (ts != NULL)
										{
											if (!ts->exists($1)) 
											{
												// M: If the variable dosen't exist;
												sprintf(errorMessage, "%d:%d Semantic error: No declaration for variable %s!", @1.first_line, @1.first_column, $1);
												yyerror(errorMessage);
												YYERROR;
											}
											else
											{
												if (ts->getValue($1) == -100)
												{
													// M: If the variable dosen't exist;
													sprintf(errorMessage, "%d:%d Semantic error: Uninitialized variable %s!", @1.first_line, @1.first_column, $1);
													yyerror(errorMessage);
													YYERROR;
												}
											}
										}
										else 
										{
											// M: If the variable dosen't exist;
											sprintf(errorMessage, "%d:%d Semantic error: No declaration for variable %s!", @1.first_line, @1.first_column, $1);
											yyerror(errorMessage);
											YYERROR;
										}
									}
									|
									TOK_INT
									|
									TOK_LEFT Expression TOK_RIGHT
									;

Read:								TOK_READ IdListReadWrite
									{
										if (ts != NULL)
										{
											if (!ts->exists($2)) 
											{
												// M: If the variable dosen't exist;
												sprintf(errorMessage, "%d:%d Semantic error: No declaration for variable %s!", @1.first_line, @1.first_column, $2);
												yyerror(errorMessage);
												YYERROR;
											}											
										}
										else 
										{
											// M: If the variable dosen't exist;
											sprintf(errorMessage, "%d:%d Semantic error: No declaration for variable %s!", @1.first_line, @1.first_column, $2);
											yyerror(errorMessage);
											YYERROR;
										}
									}
									;

Write:								TOK_WRITE IdListReadWrite 
									{
										if (ts != NULL)
										{
											if (!ts->exists($2)) 
											{
												// M: If the variable dosen't exist;
												sprintf(errorMessage, "%d:%d Semantic error: No declaration for variable %s!", @1.first_line, @1.first_column, $2);
												yyerror(errorMessage);
												YYERROR;
											}
										}
										else 
										{
											// M: If the variable dosen't exist;
											sprintf(errorMessage, "%d:%d Semantic error: No declaration for variable %s!", @1.first_line, @1.first_column, $2);
											yyerror(errorMessage);
											YYERROR;
										}
									}
									;

For:								TOK_FOR IndexExpression TOK_DO Body
									;

IndexExpression:  					TOK_ID TOK_ATTRIBUTION Expression TOK_TO Expression
									{
										if (ts != NULL)
										{
											if (!ts->exists($1)) 
											{
												// M: If the variable dosen't exist;
												sprintf(errorMessage, "%d:%d Semantic error: No declaration for variable %s!", @1.first_line, @1.first_column, $1);
												yyerror(errorMessage);
												YYERROR;
											}
										}
										else 
										{
											// M: If the variable dosen't exist;
											sprintf(errorMessage, "%d:%d Semantic error: No declaration for variable %s!", @1.first_line, @1.first_column, $1);
											yyerror(errorMessage);
											YYERROR;
										}
									}
									;
						
Body:								Statement
									|
									TOK_BEGIN StatementList TOK_END
									;

%%

int main(int argc, char* argv[])
{
	FILE *fis = fopen(argv[1],"r");
	yyin = fis;

	yyparse();
	
	if(isCorrect == 1)
	{
		printf("Correct\n");		
	}	
	else 
	{
		printf("Incorrect\n");
	}
	return 0;
}

int yyerror(const char *errorMessage)
{
	printf("Error: %s\n", errorMessage);
	isCorrect = 0;
	return 1;
}