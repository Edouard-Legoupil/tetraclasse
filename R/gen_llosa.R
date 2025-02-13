
#' @title gen_satis
#' @description generate some random data for a satisfaction survey
#' @param N number of person
#' @examples
#' base <- gen_satis(50)
#' @export

gen_satis <- function(N=500){
  # N <- 50
  set.seed(123)
  base <- data.frame(
    satis  =    sample(0:10,N,replace=TRUE)  ,
    Accessibility = sample(c("positive","negative"),N,replace=TRUE,prob = c(0.1,0.9)),
    Responsiveness =  sample(c("positive","negative"),N,replace=TRUE,prob = c(0.3,0.7)),
    Appropriateness =  sample(c("positive","negative"),N,replace=TRUE,prob = c(0.3,0.7)),
    Professionalism = sample(c("positive","negative"),N,replace=TRUE,prob = c(0.8,0.2)),
    Empathy =     sample(c("positive","negative"),N,replace=TRUE,prob = c(0.6,0.4)),
    Reliability = sample(c("positive","negative"),N,replace=TRUE,prob = c(0.7,0.3)),
    Availability = sample(c("positive","negative"),N,replace=TRUE,prob = c(0.1,0.9))
    
  )
  
  ## need to relevel the global satisfaction variable to a binary outcome
  # in order to adjust the output of the Correspondance analysis 
  base$satis  <- as.factor(base$satis > 5)
  levels(base$satis )<-c("negative","positive")
  base
}



#' @title prepare_base
#' @description reshape the survey results so that the Matrix can be processed
#'
#' @param satis_col satisfaction column name
#' @param base the base to reshape
#'
#' @examples
#' base <- gen_satis(150)
#' prepare_base(base)
#' @importFrom magrittr %>%
#' @importFrom reshape2 melt dcast
#' @importFrom tibble column_to_rownames
#' @importFrom tidyr unite
#' @importFrom dplyr filter
#' @export

prepare_base <- function(base,
                         satis_col = "satis"){
  
  base %>% 
    melt(id.vars = satis_col) %>%
    filter(value != "NA") %>%
    unite("var",variable,value) %>%
    dcast(var~satis,
          value.var="var",
          fun.aggregate=length) %>%
    column_to_rownames("var")
}





#' @title Llosa
#' @description hack Correspodance Analysis - CA - object
#' @param BID CA object to hack
#' @export
#'
Llosa <- function(BID){
  
  # BID <- res
  BID$row$coord <- cbind(BID$row$coord,0)
  BID$col$coord <- cbind(data.frame(BID$col$coord),0)
  colnames(BID$row$coord)[1:2] <- c("Dim 1", "Dim 2")
  colnames(BID$col$coord)[1:2] <- c("Dim 1", "Dim 2")
  # res <- BID
  BID
}



#' @title gen_llosa
#' @description plot the Llosa matrix
#' @param dataset the dataset to use
#' @param borne booleen do you want xlim and ylim
#' @param annotate booleen do you want annotation
#' @param annotatetext annotation text
#' @importFrom FactoMineR CA
#' @importFrom magrittr %>%
#' @importFrom tibble rownames_to_column
#' @importFrom reshape2 dcast
#' @importFrom tidyr separate
#' @importFrom ggrepel geom_text_repel
#' @importFrom stats reorder
#' @import ggplot2
#' @export
#' @examples
#' 
#' 
#' library(tetraclasse)
#' gen_satis(100) %>%
#'   prepare_base() %>%
#'   gen_llosa()
#'
#' 

gen_llosa <- function(dataset,
                      borne=FALSE,
                      annotate=TRUE,
                      annotatetext = c("Secondary- \n \"Little Influence\"",
                                       " Plus - \n \"Satisfaction\"",
                                       "Basic - \n \"Disatisfaction\"",
                                       "Key - \n \"Regardless\"")){

  res <- dataset %>% 
          CA() %>% 
          Llosa() 

  to.plot <- res$row$coord[,1,drop=FALSE] %>%
              as.data.frame() %>% 
              rownames_to_column() %>%
              separate(rowname,c("critere","sens")) %>%
              dcast(critere~sens,value.var="Dim 1") 
  
  
  #peut etre pas le plus intelligent, 
  # mais de toutes facon cela n'arrivera jamais dans une vrai enquete.
  to.plot[is.na(to.plot)] <- 0 

  NN <- ggplot(data=to.plot , 
               aes(reorder(critere, negative),negative)) +
         geom_bar(stat="identity")+
         coord_flip() +
         xlab("")
  
  PP <- ggplot(data=to.plot ,
               aes(reorder(critere, -positive),positive)) +
         geom_bar(stat="identity")+
         coord_flip()+
         xlab("")


  ## adjust results in relation with global satisfaction
  to.plot$negative <- to.plot$negative - res$col$coord["negative",1]
  to.plot$positive <- -(to.plot$positive - res$col$coord["positive",1])

  
  p <- ggplot(data=to.plot,
              aes(negative,positive)) + 
        geom_point()+
        geom_hline(aes(yintercept=0))+
        geom_vline(aes(xintercept=0))+
        geom_text_repel(aes(label=critere)) +
        theme_bw()
  
  ## Set up annotation
  annotations <- data.frame(
    xpos = c(-Inf,-Inf,Inf,Inf),
    ypos =  c(-Inf, Inf,-Inf,Inf),
    annotatetext = annotatetext,
    coul =  c("#666666","#0072BC", "#00B398","#EF4A60" ),
    hjustvar = c(0,0,1,1) ,
    vjustvar = c(0,1.0,0,1))

  if(annotate){
   p <- p +   
        geom_label(data = annotations, 
                  aes(x=xpos,y=ypos,
                      hjust=hjustvar,
                      vjust=vjustvar,
                      label=annotatetext,
                      fill = factor(coul)))
  }
  
  ## Set u bounding
  b <- max(abs(to.plot[,-1]),na.rm=TRUE)
  if (borne){
    p <-p  +
        ylim(-b,b)+
        xlim(-b,b)
    }

  
#print(p)

list( info=list(PP=PP,
                NN=NN),
      graph=p,
      coord=to.plot)


}

